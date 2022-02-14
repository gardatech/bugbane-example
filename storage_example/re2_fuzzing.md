# Фаззинг-тестирование модуля RE2
Фаззинг-тестирование модуля RE2, написанного на языке программирования C++, было выполнено с использованием фаззера с обратной связью по покрытию AFL++ в среде Arch Linux Rolling в режиме статической инструментации кода. Использованы санитайзеры ASAN, UBSAN. Для сбора информации о покрытии исходного кода использованы инструменты lcov, genhtml. Использована коллекция сэмплов, составленная на основе данных из юнит-тестов, а также данных, поступающих в модуль при нормальной работе. Использован словарь, составленный на основе изучения исходного кода тестируемого приложения.<br>
Тестирование модуля выполняется Разработчиком на регулярной основе. Результаты проведения фаззинг-тестирования помещены в электронные приложения (каталог «Электронные приложения/ДАО.2/RE2») и проанализированы на предмет выявления кодовых и архитектурных уязвимостей.<br>
Модуль реализован библиотекой с открытым исходным кодом re2 и используется в продукте RE2 Library версии 2021-11-01 для разбора данных в сложном структурированном формате RegExp.<br>

# Сборка приложения
При сборке приложения компиляторами фаззера AFL++ тестируемая функция TestOneInput в файле re2_fuzzer.cc помещается в цикл, обеспечивая persistent-режим работы фаззера. Данные от фаззера поступают в эту функцию из стандартного ввода.
<br>
Сборка выполняется следующими командами:
```
env CFLAGS="-gline-tables-only -fno-omit-frame-pointer" CXXFLAGS="-gline-tables-only -fno-omit-frame-pointer" CC=afl-clang-lto CXX=afl-clang-lto++ LD=afl-clang-lto ./fuzz_build.sh
env CFLAGS="-gline-tables-only -fno-omit-frame-pointer" CXXFLAGS="-gline-tables-only -fno-omit-frame-pointer" AFL_LLVM_LAF_ALL=1 CC=afl-clang-lto CXX=afl-clang-lto++ LD=afl-clang-lto ./fuzz_build.sh
env CFLAGS="-gline-tables-only -fno-omit-frame-pointer" CXXFLAGS="-gline-tables-only -fno-omit-frame-pointer" AFL_USE_CMPLOG=1 CC=afl-clang-lto CXX=afl-clang-lto++ LD=afl-clang-lto ./fuzz_build.sh
env CFLAGS="-gline-tables-only -fno-omit-frame-pointer" CXXFLAGS="-gline-tables-only -fno-omit-frame-pointer" AFL_USE_ASAN=1 CC=afl-clang-lto CXX=afl-clang-lto++ LD=afl-clang-lto ./fuzz_build.sh
env CFLAGS="-gline-tables-only -fno-omit-frame-pointer" CXXFLAGS="-gline-tables-only -fno-omit-frame-pointer" AFL_USE_UBSAN=1 CC=afl-clang-lto CXX=afl-clang-lto++ LD=afl-clang-lto ./fuzz_build.sh
env CFLAGS="-gline-tables-only -fno-omit-frame-pointer -O0 --coverage" CXXFLAGS="-gline-tables-only -fno-omit-frame-pointer -O0 --coverage" LDFLAGS=--coverage CC=afl-clang-lto CXX=afl-clang-lto++ LD=afl-clang-lto ./fuzz_build.sh
```
<br>

Команды запуска фаззера:
```
watch -t -n 5 afl-whatsup -s /fuzz/out
afl-fuzz -i /fuzz/in -o /fuzz/out -m none -D -M re2_fuzzer1 -- /fuzz/basic/re2_fuzzer
afl-fuzz -i /fuzz/in -o /fuzz/out -m none -S re2_fuzzer2 -c /fuzz/cmplog/re2_fuzzer -l 2 -- /fuzz/basic/re2_fuzzer
afl-fuzz -i /fuzz/in -o /fuzz/out -m none -S re2_fuzzer3 -c /fuzz/cmplog/re2_fuzzer -l 2 -L 0 -- /fuzz/laf/re2_fuzzer
afl-fuzz -i /fuzz/in -o /fuzz/out -m none -S re2_fuzzer4 -l 3 -L 0 -Z -- /fuzz/asan/re2_fuzzer
afl-fuzz -i /fuzz/in -o /fuzz/out -m none -S re2_fuzzer5 -L 0 -Z -- /fuzz/ubsan/re2_fuzzer
```
<br>Условием завершения тестирования является достижение продолжительности тестирования 1 мин.<br>


# Скриншоты работы фаззера
![Окно экземпляра №1 фаззера перед завершением тестирования](screenshots/screen2.png)<br>
![Окно экземпляра №2 фаззера перед завершением тестирования](screenshots/screen3.png)<br>
![Окно экземпляра №5 фаззера перед завершением тестирования](screenshots/screen6.png)<br>
![Статистика работы фаззеров перед завершением тестирования](screenshots/screen1.png)<br>


# Результаты
В процессе фаззинг-тестирования на 5 ядрах процессора было достигнуто условие остановки: продолжительность фаззинг-тестирования составила 1 минуту 10 секунд.<br>
Всего запусков приложения: 3.1 млн.<br>
В результате работы фаззера падений обнаружено не было.<br>
Зависаний обнаружено не было.<br>

После завершения тестирования было собрано покрытие исходного кода, полученное при запуске тестируемого приложения с каждым из обнаруженных фаззером тестовых примеров.<br>
Покрытие исходного кода составило по функциям - 47.84%, по строкам – 27.46%, по базовым блокам – 12.95%.<br>
![Отчёт о покрытии исходного кода тестируемого приложения](screenshots/coverage.png)<br>
