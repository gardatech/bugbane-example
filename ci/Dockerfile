FROM archlinux as build
RUN pacman --noconfirm -Syu \
        vim nano tmux bash-completion python python-pip \
        git make cmake gdb strace ltrace diffutils which \
        clang llvm lld gcc lib32-gcc-libs \
        lcov cloc \
        jq moreutils \
        pango ttf-liberation && \
    fc-cache

RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install weasyprint==52.5 beautifulsoup4 lxml requests


ARG GIT_ANSIFILTER_TAG="2.18"
RUN git -c advice.detachedHead=false clone --depth=1 https://gitlab.com/saalen/ansifilter.git -b ${GIT_ANSIFILTER_TAG} /ansifilter
RUN cd /ansifilter && make && make install && cd / && rm -rf /ansifilter


ARG GIT_AFLPP_TAG="3.14c"
RUN git -c advice.detachedHead=false clone --depth 1 https://github.com/AFLplusplus/AFLplusplus -b ${GIT_AFLPP_TAG} /AFLplusplus
RUN cd /AFLplusplus && \
    # включить сообщения об ошибках санитайзера UBSAN
    sed -i 's|cc_params\[cc_par_cnt++\] = "-fsanitize-undefined-trap-on-error";||g' ./src/afl-cc.c && \
    # включить сообщения об ошибках санитайзера CFISAN
    sed -i 's|"-fsanitize=cfi";|"-fsanitize=cfi";\n    cc_params\[cc_par_cnt++\] = "-fno-sanitize-trap=cfi";|g' ./src/afl-cc.c && \
    # использовать простые рамки интерфейса AFL++
    sed -i 's|#define FANCY_BOXES|// #define FANCY_BOXES|g' ./include/config.h && \
    make source-only && make install


# настройки
RUN echo -e "set -g mouse on\nset -g mode-mouse on\n" > /etc/tmux.conf && \
    sh -c 'echo set encoding=utf-8 > /root/.vimrc' && \
    echo '. /usr/share/bash-completion/bash_completion' >> ~/.bashrc && \
    echo "export PS1='"'[appsec-tools \h] \w \$ '"'" >> ~/.bashrc



FROM build as add_src

ARG GIT_RE2_TAG="2021-11-01"
RUN git -c advice.detachedHead=false clone --depth 1 https://github.com/google/re2 -b ${GIT_RE2_TAG} /src

# добавление #include <limits> перед первым встретившимся #include (для gcc>=11, clang>=12)
RUN sed -i '0,/#include/ s||#include <limits>\n#include|g' /src/re2/fuzzing/re2_fuzzer.cc

COPY fuzz_build.sh /src/
COPY sdl_vars.json /src/

WORKDIR /src



FROM add_src as appsec_tools
COPY . /appsec
RUN cd /appsec && pip3 install -e .[dev] && \
    pytest && echo "Testing AppSec Tools: OK"



FROM appsec_tools as fuzz_build_stage
RUN appsec-build -i /src -o /fuzz && \
    egrep '^\$ ' /fuzz/build.log | cut -c 3- > /fuzz/build.cmds && \
    jq '.fuzzing += {"build_cmd": "/fuzz/build.cmds"}' /src/sdl_vars.json \
        > /fuzz/sdl_vars.json



FROM fuzz_build_stage as fuzz_stage
ENV FUZZ_DURATION=65
RUN appsec-fuzz suite /fuzz



FROM fuzz_stage as coverage_stage
RUN appsec-coverage suite /fuzz



FROM coverage_stage as reproduce_stage
RUN appsec-reproduce suite /fuzz



FROM reproduce_stage as vulnmgmt
RUN appsec-vulnmgmt suite /fuzz



FROM reproduce_stage as report_stage
RUN appsec-report -i /fuzz -o re2_fuzzing_report
