/*************************************************************/
//function: 多通道DDS测试激励(需在vivado内运行仿真)
//Author  : WangYuxiao
//Email   : wyxee2000@163.com
//Data    : 2024.9.15
//Version : V 1.0
/*************************************************************/
`timescale 1 ns / 1 ps       /*定义 仿真时间单位/精度*/
`define Period 8             /*定义 时钟周期*/

`define result_path   "../sources/TB/result.txt"   /*定义 输出文件路径*/

`define channel_num  8      /*定义 DDS并行度*/
`define pinc_width   16     /*定义 激励数据位宽*/
`define data_width   16     /*定义 响应数据位宽*/

`define sim_point    32768  /*定义 仿真的采样信号点数*/
`define pinc         11796  /*定义 相位增量控制字*/


module dds_parallel_tb();
/**************************信号定义**************************/
reg clk;
reg rst_n;

reg [`pinc_width-1:0] s_tdata;
wire s_tready;

wire [`data_width*`channel_num-1:0] m_tdata;
wire m_tvalid;
reg m_tready;
/************************************************************/



/************************例化待测模块************************/
glbl glbl();

dds_parallel #(.dds_channel(`channel_num),
               .pinc_width(`pinc_width),
               .data_width(`data_width)
              ) i1 (.clk(clk),
                    .rst_n(rst_n),
                    .pinc_axis_tdata(s_tdata),
                    .pinc_axis_tready(s_tready),
                    .m_axis_tdata(m_tdata),
                    .m_axis_tvalid(m_tvalid),
                    .m_axis_tready(m_tready)
                   );
/************************************************************/



/*************************时钟及复位*************************/
initial
begin
  clk=0;
  forever
    #(`Period/2) clk=~clk;  
end

initial
begin
  rst_n=0;
  #(`Period*10.75) rst_n=1;
end
/************************************************************/



/**************************施加激励**************************/
reg stimulus_en;
initial
begin
  s_tdata=0;
  stimulus_en=1;
  @(posedge rst_n)/*复位结束后经过两个时钟周期允许施加激励*/
  begin
    @(posedge clk);
    @(posedge clk);
    while(stimulus_en)
      begin
        @(negedge clk)
        begin
          if(s_tready)
            begin
              s_tdata=`pinc;
              stimulus_en=0;
            end
          else
            begin
              s_tdata=0;
              stimulus_en=1;
            end
        end
      end
  end
end
/************************************************************/



/****************************输出****************************/
integer file_result;
integer response_num=0;
reg response_en;

initial
begin
  response_en=1;
  m_tready=1;
  file_result=$fopen(`result_path,"w");
  @(posedge m_tvalid) /*触发条件为复位结束或产生有效输出数据;此处规定产生有效输出数据后开始采集输出数据*/
  begin
    while(response_en)
      begin
        @(posedge clk)
        begin
          if(response_num==`sim_point/`channel_num)
            begin
              response_en=0;
              response_num=response_num;
              $display("time=%t, Data outputs finish,a total of %d outputs",$time,response_num);
            end
          else if(m_tvalid)
            begin
              response_en=1;
              $fwrite(file_result,"%b\n",m_tdata); /*数据进制需根据实际result.txt文件设置*/
              response_num=response_num+1;
              $display("time=%t,response_num=%d,rst_n=%b,m_tdata=%b",$time,response_num,rst_n,m_tdata); /*数据进制需根据实际result.txt文件设置*/
            end
        end
      end
  end
  $fclose(file_result);
  $display("TEST PASSED");
  $finish;
end
/************************************************************/

endmodule