FROM archlinux as base
RUN pacman --noconfirm -Syu --needed \
        vim nano tmux bash-completion python python-pip \
        git make cmake gdb strace ltrace diffutils which \
        clang llvm lld gcc lib32-gcc-libs \
        lcov cloc \
        jq moreutils \
        pango ttf-liberation && \
    fc-cache


# настройки
RUN echo -e "set -g mouse on\nset -g mode-mouse on\n" > /etc/tmux.conf && \
    sh -c 'echo set encoding=utf-8 > /root/.vimrc' && \
    echo '. /usr/share/bash-completion/bash_completion' >> ~/.bashrc && \
    echo "export PS1='"'[bugbane \h] \w \$ '"'" >> ~/.bashrc && \
    git config --global advice.detachedHead false


ARG GIT_ANSIFILTER_TAG="2.18"
RUN git clone --depth=1 https://gitlab.com/saalen/ansifilter.git -b ${GIT_ANSIFILTER_TAG} /ansifilter
RUN cd /ansifilter && make && make install && cd / && rm -rf /ansifilter


ARG GIT_AFLPP_TAG="3.14c"
RUN git clone --depth 1 https://github.com/AFLplusplus/AFLplusplus -b ${GIT_AFLPP_TAG} /AFLplusplus
RUN cd /AFLplusplus && \
    # включить сообщения об ошибках санитайзера UBSAN
    sed -i 's|cc_params\[cc_par_cnt++\] = "-fsanitize-undefined-trap-on-error";||g' ./src/afl-cc.c && \
    # включить сообщения об ошибках санитайзера CFISAN
    sed -i 's|"-fsanitize=cfi";|"-fsanitize=cfi";\n    cc_params\[cc_par_cnt++\] = "-fno-sanitize-trap=cfi";|g' ./src/afl-cc.c && \
    # использовать простые рамки интерфейса AFL++
    sed -i 's|#define FANCY_BOXES|// #define FANCY_BOXES|g' ./include/config.h && \
    make source-only && make install




FROM base AS bugbane
RUN git clone --depth=1 https://github.com/gardatech/bugbane /bugbane && \
    cd /bugbane && pip3 install .[all]




FROM bugbane AS add_src

ARG GIT_RE2_TAG="2021-11-01"
RUN git clone --depth 1 https://github.com/google/re2 -b ${GIT_RE2_TAG} /src

# добавление #include <limits> перед первым встретившимся #include (для gcc>=11, clang>=12)
RUN sed -i '0,/#include/ s||#include <limits>\n#include|g' /src/re2/fuzzing/re2_fuzzer.cc

COPY ci/fuzz_build.sh /src/
COPY ci/bugbane.json /src/

WORKDIR /src




FROM add_src AS fuzz_build
RUN bb-build -i /src -o /fuzz && \
    egrep '^\$ ' /fuzz/build.log | cut -c 3- > /fuzz/build.cmds && \
    jq '.fuzzing += {"build_cmd": "/fuzz/build.cmds", "product_version": "'${GIT_RE2_TAG}'"}' \
        /src/bugbane.json > /fuzz/bugbane.json
WORKDIR /fuzz


FROM fuzz_build AS fuzz
ENV FUZZ_DURATION=65
CMD bb-corpus suite /fuzz import-from /mnt && \
    bb-fuzz suite /fuzz && \
    bb-coverage suite /fuzz && \
    bb-reproduce suite /fuzz && \
    bb-corpus suite /fuzz export-to /mnt && \
    bb-report --name re2_fuzzing suite /fuzz && \
    # tar zcf /mnt/$(date +"%Y_%m_%d__%H_%M_%S")__re2_fuzzing.tgz \
    cp -r -t /mnt \
        coverage_report build.cmds build.log fuzz.cmds screenshots bb_results.json re2_fuzzing.md && \
    chown -R 1000:1000 /mnt/*
