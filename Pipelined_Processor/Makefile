VERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave
FLAGS = -g2012

TARGET = sim/sim.out
VCD_FILE = sim/sim.vcd

SRCS += $(wildcard rtl/*.v) $(wildcard tb/*.v)

# 默认目标：编译并运行
all: compile run

# 1. 编译阶段
compile: $(SRCS)
	@echo "Compiling Verilog files..."
	$(VERILOG) $(FLAGS) -o $(TARGET) $(SRCS)

# 2. 运行阶段 (生成 VCD 文件)
run: $(TARGET)
	@echo "Running simulation..."
	$(VVP) $(TARGET)

# 3. 查看波形阶段
wave: $(VCD_FILE)
	@echo "Opening GTKWave..."
	$(GTKWAVE) $(VCD_FILE) &

# 4. 清理垃圾文件
clean:
	@echo "Cleaning up..."
	rm -f $(TARGET) $(VCD_FILE)

.PHONY: all compile run wave clean
