# EKS 노드 `sysctl -a` OS 레벨 분석

> 이 문서는 간단한 요약을 위한 용도로, chatgpt를 통해 작성된 문서입니다.

## 분석 대상

- 원본: `1-deploy-eks/NODE1_sysctl.txt`
- 전제: 생성 직후에 가까운 EKS 워커 노드 1대의 `sysctl -a` 결과만을 기준으로 해석했다.
- 범위: 커널, 네트워크, 파일시스템, 메모리, 네임스페이스 관점의 OS 설정 분석이다.
- 제외: `ulimit`, `systemd` unit, kubelet/containerd 설정, 실제 `/etc/sysctl.d/*.conf` 파일 출처는 이 문서만으로는 확정할 수 없다.

## 한눈에 보는 결론

- 이 노드는 `Amazon Linux 2023 x86_64` 계열 커널 위에서 동작하는 전형적인 EKS 워커 노드로 보인다.
- 쿠버네티스 노드에 필요한 `ip_forward`, 느슨한 `rp_filter`, 충분한 `conntrack`/`inotify`/namespace 한도가 이미 잡혀 있다.
- 보안 하드닝은 일부 적용되어 있지만, `accept_redirects`, `send_redirects`, `kptr_restrict`, `ptrace_scope`, `legacy_tiocsti` 같은 값은 보수적인 보안 기준에서는 아직 완전히 잠겨 있지 않다.
- 네트워크/소켓 버퍼는 고성능 튜닝보다는 범용 노드 기본값에 가깝다.
- `nf_conntrack_count=148`, `fs.file-nr=1248`, `fs.aio-nr=0` 등을 보면 캡처 시점은 부팅 후 큰 부하가 없는 초기 상태로 해석할 수 있다.

## 1. 노드 정체성

- `kernel.arch = x86_64`
- `kernel.osrelease = 6.12.73-95.123.amzn2023.x86_64`
- `kernel.version = #1 SMP PREEMPT_DYNAMIC Tue Feb 24 23:31:49 UTC 2026`
- `crypto.fips_name = Amazon Linux 2023 Kernel Cryptographic API`
- `crypto.fips_enabled = 0`
- `kernel.hostname = ip-192-168-1-118.ap-northeast-2.compute.internal`

해석:

- 커널 문자열과 암호화 프레임워크 이름으로 보아 Amazon Linux 2023 기반 노드다.
- `fips_enabled=0` 이므로 FIPS 모드 강제 환경은 아니다.
- 호스트명은 EC2 내부 DNS 규칙을 따른다.

## 2. 보안/하드닝 상태

좋은 쪽:

- `fs.protected_symlinks = 1`
- `fs.protected_hardlinks = 1`
- `fs.protected_regular = 1`
- `fs.protected_fifos = 1`
- `fs.suid_dumpable = 0`
- `kernel.dmesg_restrict = 1`
- `kernel.randomize_va_space = 2`
- `vm.mmap_min_addr = 65536`
- `vm.unprivileged_userfaultfd = 0`
- `kernel.unprivileged_bpf_disabled = 1`
- `kernel.perf_event_paranoid = 2`
- `kernel.sysctl_writes_strict = 1`

의미:

- 심볼릭 링크/하드 링크 악용, SUID 코어덤프, 저주소 매핑, 비특권 BPF, 비특권 `userfaultfd` 같은 오래된 공격면을 기본적으로 줄여 둔 상태다.
- 완전한 CIS 수준 하드닝은 아니어도, 일반 클라우드 서버 기본값보다는 안전한 편이다.

관찰된 완화 지점:

- `kernel.kptr_restrict = 0`
- `kernel.yama.ptrace_scope = 0`
- `dev.tty.legacy_tiocsti = 1`
- `kernel.modules_disabled = 0`
- `kernel.kexec_load_disabled = 0`
- `net.core.bpf_jit_harden = 0`
- `vm.memfd_noexec = 0`

의미:

- 커널 포인터 노출, `ptrace`, TTY 주입, 런타임 모듈 적재, BPF JIT 하드닝, `memfd` 실행 금지 같은 항목은 엄격한 보안 기준으로 잠겨 있지 않다.
- 즉, 이 노드는 "관리형 쿠버네티스 워커로서 무난한 기본값"에 가깝고 "강한 하드닝 노드"는 아니다.

장애 복구 성향:

- `kernel.panic_on_oops = 1`
- `kernel.panic = 10`
- `kernel.panic_on_warn = 0`

의미:

- 커널 `oops` 발생 시 10초 뒤 재부팅하도록 되어 있어, 문제를 안고 계속 살아남기보다 노드를 빨리 교체/복구하는 관리형 노드 성향을 보인다.
- 반면 일반 warning 수준에서는 바로 죽지 않는다.

## 3. EKS/쿠버네티스 네트워크 관점

### 3.1 라우팅과 포워딩

- `net.ipv4.ip_forward = 1`
- `net.ipv4.conf.all.forwarding = 1`
- `net.ipv4.conf.default.forwarding = 1`

의미:

- 이 값은 사실상 "이 노드는 L3 포워더 역할을 한다"는 선언이다.
- EKS 노드는 Pod IP, Service NAT, ENI 기반 데이터 경로 처리를 위해 포워딩이 필요하므로 정상적인 상태다.
- 이 값을 하드닝 목적으로 `0`으로 내리면 Pod 통신이 깨질 수 있다.

### 3.2 Reverse Path Filter

- `net.ipv4.conf.all.rp_filter = 0`
- `net.ipv4.conf.default.rp_filter = 2`
- `net.ipv4.conf.ens5.rp_filter = 2`
- `net.ipv4.conf.ens6.rp_filter = 2`
- `net.ipv4.conf.lo.rp_filter = 2`
- `net.ipv4.conf.eni1fb02db4546.rp_filter = 2`

의미:

- `2`는 strict가 아닌 loose 모드다.
- AWS VPC CNI처럼 멀티 ENI, 비대칭 라우팅, secondary IP를 쓰는 환경에서는 strict `rp_filter=1`이 정상 패킷까지 버릴 수 있으므로, 이 설정은 EKS 노드에 더 잘 맞는다.
- 운영에서 보안만 보고 `1`로 바꾸는 것은 위험하다.

### 3.3 Loopback 관련 NAT/리다이렉트

- `net.ipv4.conf.all.route_localnet = 1`
- `net.ipv4.conf.default.route_localnet = 0`

의미:

- `all=1`은 127/8 주소를 loopback 밖으로 라우팅할 수 있게 허용하는 값이다.
- kube-proxy의 로컬 리다이렉션/NAT 패턴과 함께 보이는 경우가 많다.
- 보안적으로는 민감한 값이므로, 로컬 전용 서비스 노출 설계를 느슨하게 하면 안 된다.

### 3.4 ICMP Redirect

- `net.ipv4.conf.all.accept_redirects = 0`
- `net.ipv4.conf.default.accept_redirects = 1`
- `net.ipv4.conf.ens5.accept_redirects = 1`
- `net.ipv4.conf.ens6.accept_redirects = 1`
- `net.ipv4.conf.eni1fb02db4546.accept_redirects = 1`
- `net.ipv4.conf.all.send_redirects = 1`
- `net.ipv4.conf.default.send_redirects = 1`

의미:

- 여기서는 하드닝 방향이 완전히 닫혀 있지 않다.
- 쿠버네티스 워커 노드 관점에서는 `accept_redirects=0`, `send_redirects=0`을 더 선호하는 경우가 많다.
- 실습/기본 배포에는 큰 문제 없겠지만, 보안 기준이 높은 운영 환경이라면 우선 검토할 항목이다.

### 3.5 TCP/소켓/큐 기본값

- `net.core.default_qdisc = fq_codel`
- `net.ipv4.tcp_congestion_control = cubic`
- `net.core.somaxconn = 4096`
- `net.core.netdev_max_backlog = 1000`
- `net.core.rmem_max = 212992`
- `net.core.wmem_max = 212992`
- `net.ipv4.tcp_syncookies = 1`
- `net.ipv4.tcp_fastopen = 1`
- `net.ipv4.tcp_tw_reuse = 2`

의미:

- 현대 리눅스의 범용 기본값에 가깝다.
- 대규모 ingress, 초고 PPS, 대형 east-west 트래픽을 위한 공격적인 성능 튜닝은 아니다.
- 일반적인 실습용 또는 범용 워커 노드로는 충분하지만, 고성능 프록시 노드라면 backlog/buffer 재조정 여지가 있다.

### 3.6 Conntrack

- `net.netfilter.nf_conntrack_buckets = 65536`
- `net.netfilter.nf_conntrack_max = 131072`
- `net.netfilter.nf_conntrack_count = 148`
- `net.nf_conntrack_max = 131072`

의미:

- 현재 사용량이 매우 낮아, 캡처 시점 노드는 사실상 유휴 상태다.
- `131072`는 작은 워커 노드에서 무난한 출발점이지만, NAT, Service Mesh, L7 프록시, 외부 API fan-out이 많아지면 먼저 압박받는 커널 자원 중 하나다.
- 운영에서 Pod 수보다 연결 수가 많은 워크로드라면 `conntrack` 한도를 별도로 검토해야 한다.

### 3.7 인터페이스 형태와 CNI 추정

- `ens5`, `ens6`, `eni1fb02db4546`, `lo` 기준값이 각각 존재한다.
- `net.bridge.*` 계열 값은 dump에 보이지 않는다.

해석:

- 인터페이스 이름만 봐도 기본 NIC 외에 추가 ENI 또는 ENI 노출 장치가 붙은 형태로 보인다.
- `net.bridge.*` 부재는 `br_netfilter` 중심 구조가 아니라 ENI/IP 기반 데이터 경로일 가능성과 잘 맞는다.
- 이 해석은 sysctl 결과만으로 한 추정이지만, AWS VPC CNI 특성과는 일관적이다.

## 4. IPv6 스택 상태

- `net.ipv6.conf.all.disable_ipv6 = 0`
- `net.ipv6.conf.all.forwarding = 0`
- 인터페이스별 `mtu = 9001`
- 일부 인터페이스는 `accept_ra = 0`, 일부는 `1`

의미:

- IPv6 커널 스택 자체는 꺼져 있지 않다.
- 하지만 IPv6 라우터처럼 동작하도록 열어 둔 상태도 아니다.
- 즉, "IPv6 코드 경로는 살아 있지만 이 노드의 핵심 데이터플레인은 IPv4 중심"으로 보는 편이 안전하다.
- 실습 클러스터가 IPv4 위주라면 이 값들은 대체로 비활성 여유 상태에 가깝다.

## 5. 파일시스템, FD, inotify, namespace

- `fs.file-max = 9223372036854775807`
- `fs.nr_open = 1073741816`
- `fs.file-nr = 1248 0 9223372036854775807`
- `fs.inotify.max_user_instances = 8192`
- `fs.inotify.max_user_watches = 524288`
- `fs.mount-max = 100000`
- `kernel.pid_max = 4194304`
- `kernel.threads-max = 30111`
- `user.max_cgroup_namespaces = 15055`
- `user.max_mnt_namespaces = 15055`
- `user.max_net_namespaces = 15055`
- `user.max_pid_namespaces = 15055`
- `user.max_user_namespaces = 15055`

의미:

- 전역 FD ceiling은 사실상 병목이 아니고, 실제 한계는 프로세스별 limit와 메모리로 이동한다.
- `inotify`와 namespace 한도는 kubelet, containerd, 로그 수집기, GitOps 에이전트, 다수의 mount namespace가 붙는 컨테이너 환경을 감당하기에 충분한 편이다.
- 다만 이 값들이 높다고 해서 Pod를 많이 실을 수 있다는 뜻은 아니다. 실제 Pod 밀도는 ENI IP 수, kubelet `maxPods`, CPU/RAM, `conntrack`이 먼저 제한한다.
- `user.max_user_namespaces`가 `0`이 아니므로 user namespace를 완전히 막아 둔 하드닝 노드는 아니다.

## 6. 메모리/VM 정책

- `vm.max_map_count = 524288`
- `vm.overcommit_memory = 1`
- `vm.overcommit_ratio = 50`
- `vm.swappiness = 60`
- `vm.min_free_kbytes = 67584`
- `vm.nr_hugepages = 0`
- `vm.zone_reclaim_mode = 0`
- `kernel.numa_balancing = 0`

의미:

- `vm.max_map_count=524288`은 mmap를 많이 쓰는 워크로드에 유리하다.
- `vm.overcommit_memory=1`은 메모리 예약을 보수적으로 막지 않는 정책이다. 컨테이너 환경에서는 흔하지만, 메모리 압박이 오면 OOM 동작을 더 중요하게 봐야 한다.
- `swappiness=60`은 숫자만 보면 적극적인 편이지만, EKS 노드는 보통 swap 없이 운영되므로 실제 영향은 제한적일 가능성이 크다.
- hugepage 선예약은 없고, NUMA 최적화도 사실상 꺼져 있어 범용 가상머신 워커 노드에 가깝다.

## 7. "생성 직후" 노드라는 점을 보여주는 흔적

- `net.netfilter.nf_conntrack_count = 148`
- `fs.file-nr = 1248 0 ...`
- `fs.aio-nr = 0`
- `kernel.pty.nr = 2`
- quota 관련 카운터가 모두 `0`

의미:

- kubelet, containerd, aws-node, kube-proxy 같은 기본 에이전트만 올라온 거의 초기 상태로 보인다.
- 아직 애플리케이션 워크로드가 본격적으로 실린 흔적은 약하다.

## 운영자가 우선 검토할 값

바꿔 볼 만한 항목:

- `net.ipv4.conf.*.accept_redirects`
- `net.ipv4.conf.*.send_redirects`
- `kernel.kptr_restrict`
- `kernel.yama.ptrace_scope`
- `dev.tty.legacy_tiocsti`
- `vm.memfd_noexec`
- `net.core.bpf_jit_harden`

함부로 바꾸면 안 되는 항목:

- `net.ipv4.ip_forward`
- `net.ipv4.conf.*.rp_filter`
- `net.ipv4.conf.all.route_localnet`
- `net.netfilter.nf_conntrack_*`

이유:

- 앞의 항목은 하드닝 강화를 위해 검토할 수 있다.
- 뒤의 항목은 쿠버네티스 데이터플레인과 직접 연결되어 있어, 의미를 모르고 바꾸면 Pod 통신이나 Service/NAT가 즉시 깨질 수 있다.

## 종합

이 `sysctl -a` 결과는 "Amazon Linux 2023 기반 EKS 워커 노드의 비교적 표준적인 초기 상태"로 보인다. 보안적으로 완전히 느슨하지는 않지만, 강한 하드닝보다 쿠버네티스 네트워킹 호환성과 운영 편의에 더 무게를 둔 값들이다. 특히 `ip_forward`, loose `rp_filter`, `route_localnet`, `conntrack` 구성은 EKS 노드답고, 반대로 `redirect`, `ptrace`, `kptr`, `tty`, `memfd` 쪽은 운영 보안 정책에 따라 추가 하드닝 여지가 남아 있다.
