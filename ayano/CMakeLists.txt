cmake_minimum_required(VERSION 3.16)

project(ayano LANGUAGES CXX)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup()

qt_add_executable(ayano_exe
    main.cpp
)

qt_add_qml_module(ayano_exe
    URI ayano
    QML_FILES
        qml/Main.qml
)

target_link_libraries(ayano_exe
    PRIVATE Qt6::Quick
)
