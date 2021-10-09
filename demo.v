module demo(clk,rst,sure,code,led,sega,segb,RGB_led);
 
	input clk;//时钟.
	input rst;//复位.
	input sure;//确认键.
	input [3:0] code;//四路拨动开关密码.
	output [2:0] led;//错误提示灯.
	output [8:0] sega;//第一根数码管(右).
	output [8:0] segb;//第二根数码管(左).
	output [2:0]RGB_led;
 
	parameter password = 4'b1001;//设置密码.
	
	reg [2:0]rgb;//rgb激励信号
	reg [2:0] sgn;//三位指示灯信号
	reg [8:0] seg [4:0];//用来储存数码管数字显示数据.
	reg [8:0] seg_data [1:0];//数码管显示信号
	reg [2:0] cnt;//计数器,用以统计错误次数.
	reg [2:0] cnt_rst;
	reg lock;//程序锁,以避免次数用完后或者密码正确之后的误操作.
 
	wire cfm_dbs;//消抖后的确认脉冲.
 
	initial begin//初始化.
			rgb<=2'b111;
	seg[0] <= 9'h3f;//数码管显示数字0信号.
	seg[1] <= 9'h06;//数字1信号.
	seg[2] <= 9'h5b;//数字2信号.
	seg[3] <= 9'h4f;//数字3信号.
	seg[4] <= 9'h66;//数字4信号.
	seg_data[0] <= 9'h3f;//数码管初始显示数字0.
	seg_data[1] <= 9'h3f;
	cnt <= 3'b100;//错误计数器初始值为3.
	cnt_rst<=3'b010;//这样计数不好，还是应该使用cnt，当cnt两次为0且无1的情况下，则完全锁死
	end
 
	always @ (posedge clk or negedge rst)//时钟边沿触发或复位按键触发.
	begin
		if(!rst)begin//复位操作.
			sgn <= 3'b111;//两灯均灭.
			rgb<=3'b111;//
			seg_data[0] <= seg[4];//第一根显示数字4.
			seg_data[1] <= seg[0];//第二根显示数字0.	
//			lock <= 1'b1;
			if(cnt_rst==3'b000)begin lock<=1'b0; end	//未防抖搞计数就不太行
			else begin lock<=1'b1;end 
			cnt <= 3'b100;//计数器复位到4.
		end
		else if(cfm_dbs && lock)begin//按下确认键,此处用的消抖后的脉冲信号.若程序锁已锁,此下代码均不会再被执行.
			if(code == password)begin//密码正确.
				rgb<=3'b000;//rgb亮白灯
				sgn <= 3'b111;//绿灯亮.
				seg_data[0] <= 9'h40;//密码输入正确后两根数码管显示两根横线.
				seg_data[1] <= 9'h40;
				lock <= 0;//程序锁死,防止解锁成功后还能进行操作.
				cnt_rst<=3'b010;
				end
			else if(cnt == 3'b100)begin
				sgn <= 3'b111;//红灯都灭.
				seg_data[0] <= seg[3];//数码管显示数字3.
				cnt <= cnt-3'b001;//计数器减1.
				end
			else if(cnt == 3'b011) begin
				sgn <= 3'b110;//红灯亮1个.
				seg_data[0] <= seg[2];//数码管显示数字2.
				cnt <= cnt-3'b001;
				end
			else if(cnt == 3'b010) begin
				sgn <= 3'b100;//红灯亮两个.
				seg_data[0] <= seg[1];//数码管显示数字1.
				cnt <= cnt-3'b001;
				end
			else if(cnt == 3'b001)begin
				sgn <= 3'b000;//红灯全量
				seg_data[0] <= seg[0];//数码管显示数字0.
				lock <= 0;//程序锁死.（次数不足）
				rgb<=3'b010;//rhb亮紫灯
				cnt_rst<=cnt_rst-3'b001;
				end
			end
	end
 
	assign led = sgn;//绿灯亮代表密码正确,红灯反之.
	assign sega = seg_data[0];//第一根数码管通过输入信号变化改变数值
	assign segb = seg_data[1];//第二根数码管其实一直显示数字0
	assign RGB_led=rgb;
	debounce sured (//调用消抖模块,用以消抖确认键.
		.clk (clk),
		.rst (rst),
		.key (sure),
		.key_pulse (cfm_dbs));
 
endmodule