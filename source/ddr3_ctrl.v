module ddr3_ctrl#(
  parameter          CTRL_ADDR_WIDTH  = 28,
  parameter          MEM_DQ_WIDTH     = 16,
  parameter          MEM_SPACE_AW     = 18
)(
  input                             core_clk           ,//ddr接口用户时钟
  input                             core_clk_rst_n     ,
  input                             ddrc_init_done     ,
  //axi_interface
  output wire [CTRL_ADDR_WIDTH-1:0]      o_m_axi_awaddr     /* synthesis PAP_MARK_DEBUG="true" */,    
  output wire [3:0]                      o_m_axi_awlen      /* synthesis PAP_MARK_DEBUG="true" */,  
  input  wire                            i_m_axi_awready    /* synthesis PAP_MARK_DEBUG="true" */,  
  output wire                            o_m_axi_awvalid    /* synthesis PAP_MARK_DEBUG="true" */, 

  output wire [MEM_DQ_WIDTH*8-1:0]       o_m_axi_wdata      /* synthesis PAP_MARK_DEBUG="true" */,         
  input  wire                            i_m_axi_wready     /* synthesis PAP_MARK_DEBUG="true" */,     
  input  wire                            i_m_axi_wusero_last/* synthesis PAP_MARK_DEBUG="true" */,  

  output wire [CTRL_ADDR_WIDTH-1:0]      o_m_axi_araddr     /* synthesis PAP_MARK_DEBUG="true" */,    
  output wire [3:0]                      o_m_axi_arlen      /* synthesis PAP_MARK_DEBUG="true" */,  
  input  wire                            i_m_axi_arready    /* synthesis PAP_MARK_DEBUG="true" */,  
  output wire                            o_m_axi_arvalid    /* synthesis PAP_MARK_DEBUG="true" */, 

  input  wire [MEM_DQ_WIDTH*8-1:0]       i_m_axi_rdata      /* synthesis PAP_MARK_DEBUG="true" */,           
  input  wire                            i_m_axi_rlast      /* synthesis PAP_MARK_DEBUG="true" */,  
  input  wire                            i_m_axi_rvalid     /* synthesis PAP_MARK_DEBUG="true" */
);

/*************************参数****************************/
//ddr3
parameter   P_ST_IDLE           =          'd0          ,
          
            P_ST_WRITE_START    =          'd1          ,
            P_ST_WRITE_TRANS    =          'd2          ,
            P_ST_WRITE_END      =          'd3          ,
          
            P_ST_READ_START     =          'd4          ,
            P_ST_READ_TRANS     =          'd5          ,
            P_ST_READ_END       =          'd6          ;
//fifo_to_uart
parameter   P_ST_UART_IDLE      =          'd0          ,
            P_ST_UART_START     =          'd1          ,
            P_ST_UART_TRANS     =          'd2          ,
            P_ST_UART_END       =          'd3          ,
            P_ST_UART_FINISH    =          'd4          ;



/*************************寄存器**************************/ 
//ddr3
reg     [CTRL_ADDR_WIDTH-1:0]      r_m_axi_awaddr       /* synthesis PAP_MARK_DEBUG="true" */;
reg     [3:0]                      r_m_axi_awlen        /* synthesis PAP_MARK_DEBUG="true" */;
reg                                r_m_axi_awvalid      /* synthesis PAP_MARK_DEBUG="true" */;
reg     [MEM_DQ_WIDTH*8-1:0]       r_m_axi_wdata        /* synthesis PAP_MARK_DEBUG="true" */;
reg     [CTRL_ADDR_WIDTH-1:0]      r_m_axi_araddr       /* synthesis PAP_MARK_DEBUG="true" */;
reg     [3:0]                      r_m_axi_arlen        /* synthesis PAP_MARK_DEBUG="true" */;
reg                                r_m_axi_arvalid      /* synthesis PAP_MARK_DEBUG="true" */;
reg     [MEM_DQ_WIDTH*8-1:0]       r_m_axi_rdata        /* synthesis PAP_MARK_DEBUG="true" */;

reg                                r_wr_start           /* synthesis PAP_MARK_DEBUG="true" */;
reg                                r_rd_start           /* synthesis PAP_MARK_DEBUG="true" */;
reg     [3:0]                      r_wr_cnt             /* synthesis PAP_MARK_DEBUG="true" */;
reg     [3:0]                      r_rd_cnt             /* synthesis PAP_MARK_DEBUG="true" */;

reg     [7:0]                      r_st_current_write   /* synthesis PAP_MARK_DEBUG="true" */;
reg     [7:0]                      r_st_current_read    /* synthesis PAP_MARK_DEBUG="true" */;
reg     [7:0]                      r_st_next_write      /* synthesis PAP_MARK_DEBUG="true" */;
reg     [7:0]                      r_st_next_read       /* synthesis PAP_MARK_DEBUG="true" */;



/*************************网表****************************/
//ddr3
wire                               ddr_rst             ;
/*************************组合逻辑************************/
//ddr3
assign ddr_rst                  = ~ core_clk_rst_n     ;
//ddr3寄存器连接输出端口
assign o_m_axi_awaddr           = r_m_axi_awaddr       ;   
assign o_m_axi_awlen            = r_m_axi_awlen        ;   
assign o_m_axi_awvalid          = r_m_axi_awvalid      ;   
assign o_m_axi_wdata            = r_m_axi_wdata        ;   
assign o_m_axi_araddr           = r_m_axi_araddr       ;   
assign o_m_axi_arlen            = r_m_axi_arlen        ;   
assign o_m_axi_arvalid          = r_m_axi_arvalid      ;   


/*************************状态机**************************/
//ddr3写状态机：第一段状态机
always@(posedge core_clk)
  if(ddr_rst)
    r_st_current_write <= P_ST_IDLE;
  else
    r_st_current_write <= r_st_next_write;

//状态机 - 组合逻辑
always @(*)
  case (r_st_current_write)
    P_ST_IDLE          : r_st_next_write <= P_ST_WRITE_START                                          ;
    //P_ST_IDLE：启动之后开始传输
    P_ST_WRITE_START   : r_st_next_write <= r_wr_start          ? P_ST_WRITE_TRANS : P_ST_WRITE_START ;
    //P_ST_WRITE_START时 判断r_wr_start信号 来进行状态的跳转
    P_ST_WRITE_TRANS   : r_st_next_write <= i_m_axi_wusero_last ? P_ST_WRITE_END   : P_ST_WRITE_TRANS ;
    //P_ST_WRITE_TRANS：判断 写最后一个标记信号i_m_axi_wusero_last 如果是最后一个就跳转到结束状态
    P_ST_WRITE_END     : r_st_next_write <= (r_st_current_read == P_ST_READ_END) ? P_ST_IDLE : P_ST_WRITE_END ;
    //P_ST_WRITE_END: 在这里判断读状态机的状态 如果读取状态机也结束了 那么回到IDLE 否则继续等
    default            : r_st_next_write <= P_ST_IDLE ;
  endcase

always@(posedge core_clk)
  if(r_st_current_write == P_ST_WRITE_START)
    r_wr_start <= 'd1;
  else
    r_wr_start <= 'd0;

//ddr3读状态机
always@(posedge core_clk)
  if(ddr_rst)
    r_st_current_read <= P_ST_IDLE;
  else
    r_st_current_read <= r_st_next_read;

always @(*)
  case (r_st_current_read)
    P_ST_IDLE          : r_st_next_read <= (r_st_current_write == P_ST_WRITE_END) ? P_ST_READ_START : P_ST_IDLE       ;
    //写完了再开始读 剩下的逻辑和写状态机的一样
    P_ST_READ_START    : r_st_next_read <= r_rd_start                             ? P_ST_READ_TRANS : P_ST_READ_START ;
    P_ST_READ_TRANS    : r_st_next_read <= i_m_axi_rlast                          ? P_ST_READ_END   : P_ST_READ_TRANS ;
    P_ST_READ_END      : r_st_next_read <= P_ST_IDLE ;
    default            : r_st_next_read <= P_ST_IDLE ;
  endcase

always@(posedge core_clk)
  if(r_st_current_read == P_ST_READ_START)
    r_rd_start <= 'd1;
  else
    r_rd_start <= 'd0;


/*************************时序逻辑************************/
//ddr3
//AXI写地址 测试时一直给0
always@(posedge core_clk) 
  if(r_wr_start)
    r_m_axi_awaddr <= 'd0;
  else
    r_m_axi_awaddr <= 'd0;

//AXI读地址 测试时一直给0
always@(posedge core_clk) 
  if(r_rd_start)
    r_m_axi_araddr <= 'd0;
  else
    r_m_axi_araddr <= 'd0;

//写突发长度
always@(posedge core_clk) begin
  r_m_axi_awlen  <= 4'b1111;
end

//读突发长度
always@(posedge core_clk) begin
  r_m_axi_arlen  <= 4'b1111;
end

//awvalid：写起始信号
always@(posedge core_clk)begin
    if(ddr_rst)begin
    r_m_axi_awvalid <= 'd0;
  end else if(r_wr_start)begin
    //写开始
    r_m_axi_awvalid <= 'd1;
  end else if((o_m_axi_awvalid && i_m_axi_awready))begin
    //握手完成 变回0
    r_m_axi_awvalid <= 'd0;
  end else begin
    r_m_axi_awvalid <= r_m_axi_awvalid;
  end
end

//wdata 写进去的数据
always@(posedge core_clk)
  if(ddr_rst || i_m_axi_wusero_last)
    r_m_axi_wdata <= 'd0;
  else if(i_m_axi_wready)
    //自增 保证每次写入的数据都不一样
    r_m_axi_wdata <= r_m_axi_wdata + 'd1;
  else
    r_m_axi_wdata <= r_m_axi_wdata;


//r_wr_cnt：仅用于测试计数 没有其他地方使用到
always@(posedge core_clk)
  if(ddr_rst || i_m_axi_wusero_last)
    //写到了最后一个信号 全部写完了 cnt复位
    r_wr_cnt <= 'd0;
  else if(i_m_axi_wready)
    r_wr_cnt <= r_wr_cnt + 'd1;
  else
    r_wr_cnt <= r_wr_cnt;


//arvalid：读取有效信号 同写信号
always@(posedge core_clk)
  if(ddr_rst)
    r_m_axi_arvalid <= 'd0;
  else if(r_rd_start)
    //读取要开始了 给1
    r_m_axi_arvalid <= 'd1;
  else if(o_m_axi_arvalid && i_m_axi_arready)
    //握手成功了 恢复0
    r_m_axi_arvalid <= 'd0;
  else
    r_m_axi_arvalid <= r_m_axi_arvalid;


//rdata
always@(posedge core_clk)
  if(i_m_axi_rvalid)
    //ip的信号拉高时候 表示读取的数据出来了 把数据寄存到寄存器
    r_m_axi_rdata <= i_m_axi_rdata;
  else
    r_m_axi_rdata <= r_m_axi_rdata;


endmodule