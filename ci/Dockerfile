FROM ubuntu:22.04 as base
ARG DEBIAN_FRONTEND=noninteractive

ARG LLVM="15"
ARG GCC="12"

RUN : \
    && apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install --no-install-suggests --no-install-recommends \
        automake autoconf make \
        cmake ninja-build \
        gcc-${GCC} g++-${GCC} gcc-${GCC}-plugin-dev gcc-${GCC}-multilib g++-${GCC}-multilib \
        clang-${LLVM} llvm-${LLVM} libc++abi-${LLVM}-dev libc++-${LLVM}-dev \
        llvm-${LLVM}-dev llvm-${LLVM}-tools lld-${LLVM} \
        python3 python3-dev python3-pip \
        bzip2 less file vim psmisc moreutils \
        gdb strace ltrace \
        ansifilter pango1.0-tools \
        tmux bash-completion \
        git lcov cloc jq curl gawk \
    && rm -rf /var/lib/apt/lists/* \
    && :

RUN : \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${LLVM} 0 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${LLVM} 0 \
    && update-alternatives --install /usr/bin/llvm-profdata llvm-profdata /usr/bin/llvm-profdata-${LLVM} 0 \
    && update-alternatives --install /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-${LLVM} 0 \
    && update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-${LLVM} 0 \
    && update-alternatives --install /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-${LLVM} 0 \
    && update-alternatives --install /usr/bin/llvm-ranlib llvm-ranlib /usr/bin/llvm-ranlib-${LLVM} 0 \
    && update-alternatives --install /usr/bin/lld lld /usr/bin/lld-${LLVM} 0 \
    && update-alternatives --install /usr/bin/ld.lld ld.lld /usr/bin/ld.lld-${LLVM} 0 \
    && : \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC} 0 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC} 0 \
    && :


# install firefox-esr from mozilla's ppa (thanks ubuntu for using snaps)
RUN : \
    && apt-get update \
    && apt-get -y install --no-install-suggests --no-install-recommends \
        software-properties-common gpg-agent \
    && add-apt-repository -y ppa:mozillateam/ppa \
    && apt-get update \
    && apt-get -y install --no-install-suggests --no-install-recommends \
        firefox-esr firefox-esr-geckodriver \
    && rm -rf /var/lib/apt/lists/* \
    && :


# настройки
RUN : \
    && echo -e "set -g mouse on\nset -g mode-mouse on\n" > /etc/tmux.conf \
    && sh -c 'echo set encoding=utf-8 > /root/.vimrc' \
    && echo '. /usr/share/bash-completion/bash_completion' >> ~/.bashrc \
    && echo "export PS1='"'[bugbane \h] \w \$ '"'" >> ~/.bashrc \
    && git config --global advice.detachedHead false \
    && :


# AFL++
ARG GIT_AFLPP_BRANCH="dev"
ARG GIT_AFLPP_COMMIT="v4.08c"
ARG AFLPP_SRC_DIR="/AFLplusplus"
ENV AFLPP_SRC_DIR="$AFLPP_SRC_DIR"
RUN : \
    && git clone https://github.com/AFLplusplus/AFLplusplus \
        -b "$GIT_AFLPP_BRANCH" "$AFLPP_SRC_DIR" \
    && cd "$AFLPP_SRC_DIR" \
    && git reset --hard "$GIT_AFLPP_COMMIT" \
    && sed -i 's|cc_params\[cc_par_cnt++\] = "-fsanitize-undefined-trap-on-error";||g' ./src/afl-cc.c \
    && sed -i 's|"-fsanitize=cfi";|"-fsanitize=cfi";\n    cc_params\[cc_par_cnt++\] = "-fno-sanitize-trap=cfi";|g' ./src/afl-cc.c \
    && sed -i 's|#define FANCY_BOXES|// #define FANCY_BOXES|g' ./include/config.h \
    && sed -i 's|#define STATS_UPDATE_SEC .*$|#define STATS_UPDATE_SEC 5|g' ./include/config.h \
    && export NO_NYX=1 \
    && export CC=clang CXX=clang++ \
    && make source-only \
    && make install \
    && :



FROM base AS bugbane
ENV PIP_NO_CACHE_DIR=1
# зависимости BugBane (необязательно ставить отдельно, здесь - только для кэширования Docker)
RUN : \
    && pip3 install -U pip \
    && pip3 install build \
    && pip3 install \
        beautifulsoup4 lxml Jinja2 requests selenium WeasyPrint==52.5 wheel \
        pytest pytest-mock \
    && :

# bugbane
ARG GIT_BUGBANE_BRANCH="dev"
ARG GIT_BUGBANE_COMMIT="71593f8"
RUN : \
    && git clone https://github.com/gardatech/bugbane -b "$GIT_BUGBANE_BRANCH" /bugbane \
    && cd /bugbane \
    && git reset --hard "$GIT_BUGBANE_COMMIT" \
    && pip3 install -e .[all] \
    && pytest -q \
    && :



FROM bugbane AS add_src
ARG GIT_RE2_TAG="2021-11-01"
RUN git clone --depth 1 https://github.com/google/re2 -b "$GIT_RE2_TAG" /src

# добавление #include <limits> перед первым встретившимся #include (для gcc>=11, clang>=12)
RUN sed -i '0,/#include/ s||#include <limits>\n#include|g' /src/re2/fuzzing/re2_fuzzer.cc

COPY ci/fuzz_build.sh /src/
COPY ci/bugbane.json /src/

WORKDIR /src



FROM add_src AS fuzz_build
RUN : \
    && bb-build -vv -i /src -o /fuzz \
    && egrep '^\$ ' /fuzz/build.log | cut -c 3- > /fuzz/build.cmds \
    && jq '.fuzzing += {"build_cmd": "/fuzz/build.cmds", "product_version": "'$GIT_RE2_TAG'"}' \
        /fuzz/bugbane.json | sponge /fuzz/bugbane.json \
    && :
WORKDIR /fuzz



FROM fuzz_build AS fuzz
ARG FUZZ_DURATION=65
ARG FUZZ_TARGET="re2_fuzzer"
ARG STORAGE="/mnt"

ENV FUZZ_DURATION="$FUZZ_DURATION"
ENV FUZZ_TARGET="$FUZZ_TARGET"
ENV STORAGE="$STORAGE"

ENV AFL_FAST_CAL=1
ENV AFL_DISABLE_TRIM=1
ENV AFL_CMPLOG_ONLY_NEW=1
ENV AFL_NO_ARITH=1

ENV AFL_TRY_AFFINITY=1
ENV AFL_SKIP_CPUFREQ=1

ENV TZ=Europe/Moscow

CMD : \
    && export AFL_MAP_SIZE=$(./laf/re2_fuzzer - 2>&1 </dev/null | grep AFL_MAP_SIZE | egrep -o '[0-9]+') \
    && if [ -z $AFL_MAP_SIZE ]; then unset AFL_MAP_SIZE; fi \
    && bb-corpus -vv suite . import-from "$STORAGE" \
    && bb-fuzz -vv --max-cpus $(nproc) suite . \
    && find screens/ -type f | sort -V | xargs -I% sh -c "echo; cat %; echo" \
    && bb-coverage -vv suite . \
    && tar jcf coverage_report.tar.bz2 coverage_report \
    && bb-reproduce -vv suite . \
    && bb-corpus -vv suite . export-to "$STORAGE" \
    && bb-report -vv --name fuzz_re2 --html-screener selenium suite . \
    && TESTED_APP_VER=$(git -C /src rev-parse --short HEAD) \
    && CUR_DATE=$(date +'%Y_%m_%d__%H_%M_%S') \
    && STORAGE_DIR="$STORAGE/${CUR_DATE}__$TESTED_APP_VER/" \
    && mkdir -p "$STORAGE_DIR" \
    && { cp --remove-destination -r -t "$STORAGE_DIR" \
            *.md screens screenshots \
            dictionaries \
            build.log *.cmd* *build*.sh \
            coverage_report.tar.bz2 \
            bb_results.json bugbane.json \
            bug_samples \
            2>/dev/null || :; } \
    && chown -R 1000:1000 "$STORAGE_DIR" \
    && :
