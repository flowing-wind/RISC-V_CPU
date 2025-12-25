# --- Vivado Tcl Script for RISC-V Regression Test ---

# 1. 设置仿真超时时间 (防止死循环导致脚本卡死)
set timeout_time "200us"

# 2. 获取所有的 hex 文件列表
set hex_files [get_files *.hex]

# 准备统计变量
set pass_count 0
set fail_count 0
set failed_tests {}

puts "\n========================================"
puts "Starting RISC-V Regression Test"
puts "Found [llength $hex_files] test cases."
puts "========================================\n"

# 3. 循环遍历每个测试文件
foreach hex_file $hex_files {
    set test_name [file tail $hex_file]
    
    # 忽略非测试用的 hex 文件（如果有的话，比如 current_test.hex 本身）
    if {$test_name == "current_test.hex"} { continue }

    puts "Running Test: $test_name ..."

    # 4. 将当前的 hex 文件复制为 Testbench 读取的通用文件名
    # file copy -force 会覆盖旧文件
    file copy -force $hex_file "E:/Projects/RISC-V_CPU/Pipelined_Processor/tcl/current_test.hex"

    # 5. 重置仿真时间到 0
    restart

    # 6. 运行仿真
    # 使用 run 命令。如果 Verilog 中触发了 $stop，run 会提前结束。
    # 如果 Verilog 死循环，run 会在 timeout_time 后强制结束。
    run $timeout_time

    # 7. 检查结果
    set status_val [get_value -radix unsigned /tb_riscv/test_status]

    # 判断逻辑 (1 是 Pass, 2 是 Fail, 0 是超时)
    if {$status_val == 1} {
        puts "  -> PASS"
        incr pass_count
    } else {
        if {$status_val == 2} {
            # 获取一下错误数据方便调试
            set data_val [get_value -radix unsigned /tb_riscv/tohost_data]
            puts "  -> FAIL (Verilog detected error value: $data_val)"
        } else {
            puts "  -> FAIL (Timeout - test_status is still 0)"
        }
        incr fail_count
        lappend failed_tests $test_name
    }
}

# 8. 输出最终报告
puts "\n========================================"
puts "Test Summary"
puts "========================================"
puts "Total Passed: $pass_count"
puts "Total Failed: $fail_count"

if {$fail_count > 0} {
    puts "Failed Tests:"
    foreach f $failed_tests {
        puts "  - $f"
    }
} else {
    puts "ALL TESTS PASSED! CONGRATULATIONS!"
}
puts "========================================"