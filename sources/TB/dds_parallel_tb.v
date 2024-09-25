/*************************************************************/
//function: 多通道DDS测试激励(需在vivado内运行仿真)
//Author  : WangYuxiao
//Email   : wyxee2000@163.com
//Data    : 2022.9.1
//Version : V 1.1
/*************************************************************/
`timescale 1 ns / 1 ps       /*定义 仿真时间单位/精度*/
`define Period 8             /*定义 时钟周期*/

`define result_path   "../sources/TB/result.txt"   /*定义 输出文件路径*/
`define sim_point  16                              /*定义 仿真点数*/

`define channel_num  8    /*定义 DDS并行度*/
`define pinc_width   16   /*定义 激励数据位宽*/
`define data_width   16   /*定义 响应数据位宽*/

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
              s_tdata=11796;
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
integer file_response;
integer file_result;
integer response_num=0;
reg response_en;
reg [`data_width*`channel_num-1:0] response;

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
          if($feof(file_response))
            begin
              response=0;
              response_en=0;
              response_num=response_num;
              $display("time=%t, Data outputs finish,a total of %d outputs",$time,response_num);
            end
          else if(m_tvalid)
            begin
              response=response;
              response_en=1;
              $fwrite(file_result,"%b\n",m_tdata); /*数据进制需根据实际result.txt文件设置*/
              if(response_num==0)
                begin
                  $display("time=%t, Data outputs start, the output is delayed by %d clock cycles relative to the input",$time,(time_data_out-time_data_in)/`Period); 
                  response_num=response_num+1;
                end
              else
                response_num=response_num+1;

              if(m_tdata==response)
                $display("time=%t,response_num=%d,rst_n=%b,m_tdata=%b",$time,response_num,rst_n,m_tdata); /*数据进制需根据实际response.txt文件设置*/
              else
                begin
                  $display("TEST FALLED : time=%t,response_num=%d,rst_n=%b,m_tdata is %b but should be %b",$time,response_num,rst_n,m_tdata,response); /*数据进制需根据实际response.txt文件设置*/
                  $finish; /*若遇到测试失败的测试向量后需立即停止测试,则此处需要finish;若遇到测试失败的测试向量后仍继续测试,此处需注释掉finish*/
                end
              $fscanf(file_response,"%b",response); /*数据进制需根据实际response.txt文件设置*/
            end
        end
      end
  end
  $fclose(file_response);
  $fclose(file_result);
  $display("TEST PASSED");
  $finish;
end
/************************************************************/

endmodule