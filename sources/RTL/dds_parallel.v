/*************************************************************/
//function: 多通道DDS
//Author  : WangYuxiao
//Email   : wyxee2000@163.com
//Data    : 2024.9.8
//Version : V 1.0
/*************************************************************/
`timescale 1 ns / 1 ps

module dds_parallel (clk,rst_n,pinc_axis_tdata,pinc_axis_tready,m_axis_tdata,m_axis_tvalid,m_axis_tready);
/************************************************工作参数设置************************************************/
parameter dds_channel = 8;   /*DDS并行度*/
parameter pinc_width = 16;   /*DDS IP核中设置的相位增量控制字位宽*/
parameter data_width = 16;   /*DDS IP核中设置的信号输出位宽*/
/***********************************************************************************************************/
input clk;                                        /*系统时钟*/
input rst_n;                                      /*低电平异步复位信号*/

input [pinc_width-1:0] pinc_axis_tdata;           /*DAC数字信号相位增量控制字*/
output reg pinc_axis_tready;                      /*向上游模块发送读请求或读确认信号,高电平有效*/

output [data_width*dds_channel-1:0] m_axis_tdata; /*输出数据*/
output m_axis_tvalid;                             /*输出数据有效标志,高电平有效*/
input m_axis_tready;                              /*下游模块传来的读请求或读确认信号,高电平有效*/



/**********************************************例化多路DDS IP核**********************************************/
wire [dds_channel-1:0] dds_out_tvalid; /*每个DDS核的输出有效标志,高电平有效*/
wire [dds_channel-1:0] dds_in_tready;  /*每个DDS核的相位控制字允许输入标志,高电平有效*/
wire phase_tready;
reg phase_tvalid;                      /*每个DDS核的相位控制字输入有效标志,高电平有效*/
wire [pinc_width-1:0] dds_pinc;        /*每个DDS核的相位增量*/
reg [pinc_width-1:0] pinc_reg;         /*pinc_axis_tdata输入寄存器*/

assign m_axis_tvalid=&dds_out_tvalid;  /*各DDS核输出均有效时,合路数据输出有效*/
assign phase_tready=&dds_in_tready;    /*各DDS核均允许输入相位控制字时,phase_tready为高*/
assign dds_pinc=pinc_reg*dds_channel;

genvar i;
generate
  for(i=1;i<=dds_channel;i=i+1)
    begin
      dds U_dds_core (.aclk(clk),
                      .aresetn(rst_n),
                      .s_axis_phase_tvalid(phase_tvalid),
                      .s_axis_phase_tready(dds_in_tready[i-1]),
                      .s_axis_phase_tdata({pinc_reg*(i-1),dds_pinc}), /*[pinc_width*2-1:pinc_width]=poff, [pinc_width-1:0]=pinc*/
                      .m_axis_data_tvalid(dds_out_tvalid[i-1]),
                      .m_axis_data_tready(m_axis_tready),
                      .m_axis_data_tdata(m_axis_tdata[data_width*i-1:data_width*(i-1)])
                     );
    end
endgenerate
/***********************************************************************************************************/



/******************************************更新相位控制字进入DDS IP核******************************************/

reg state;
always@(posedge clk or negedge rst_n)
begin
  if(!rst_n)
    begin
      pinc_reg<=0;
      phase_tvalid<=0;
      pinc_axis_tready<=0;
      state<=0;
    end
  else
    begin
      case(state)
        0 : begin/*等待有效输入*/
              if(pinc_reg==pinc_axis_tdata)
                begin
                  pinc_reg<=pinc_reg;
                  phase_tvalid<=phase_tvalid;
                  pinc_axis_tready<=1;
                  state<=0;
                end
              else
                begin
                  pinc_reg<=pinc_axis_tdata;
                  phase_tvalid<=1;
                  pinc_axis_tready<=0;
                  state<=1;
                end
            end

        1 : begin/*等待输入被读取*/
              if(phase_tready)
                begin
                  pinc_reg<=pinc_reg;
                  phase_tvalid<=1;
                  pinc_axis_tready<=1;
                  state<=0;
                end
              else
                begin
                  pinc_reg<=pinc_reg;
                  phase_tvalid<=phase_tvalid;
                  pinc_axis_tready<=pinc_axis_tready;
                  state<=state;
                end
            end
      endcase
    end
end
/***********************************************************************************************************/

endmodule