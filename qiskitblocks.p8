pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--qiskitblockspico
--by javafxpert

qbcircs={}

--player pos on circuits
sel_circ_idx=0
sel_circ_row=0
sel_circ_col=0
sel_circ=nil
sel_sv={}



function _init()
 map_setup()
 text_setup()
 make_player()
 
 make_circs()
 build_popup_menu()

 game_win=false
 game_over=false
end

function _update()
 if (not game_over) then
  if (not active_text) then
   update_map()
   move_player()
   check_win_lose()
   if sel_circ and 
    sel_circ.is_dirty() then
    --sel_circ.set_dirty(false)
    local qc=sel_circ.comp_circ()
    local res = simulate(qc,"statevector")
    compute_statevector(res)
    sel_circ.prt()
   end  
  end
 else
  if (btnp(❎)) extcmd("reset")
 end
end

function _draw()
 cls()
 if (not game_over) then
  draw_map()
  draw_circs()
  draw_probs()
  draw_player()
  draw_text()
  --if (btn(🅾️)) show_inventory()
  if (btnp(❎)) hnd_input()
  if (btnp(🅾️)) hnd_inp_del()
 else
  draw_win_lose()
 end
end
-->8
--map code

function map_setup()
 --timers
 timer=0
 anim_time=30
 
 --map tile settings
 wall=0
 key=1
 door=2
 anim1=3
 anim2=4
 text=5
 lose=6
 win=7
end

function update_map()
 if (timer<0) then
  toggle_tiles()
  timer=anim_time
 end
 timer-=1
end

function draw_map()
 mapx=flr(p.x/16)*16
 mapy=flr(p.y/16)*16
 camera(mapx*8,mapy*8)
 
 map(0,0,0,0,128,64)
end

function is_tile(tile_type,x,y)
 tile=mget(x,y)
 has_flag=fget(tile,tile_type)
 return has_flag
end

function can_move(x,y)
 return not is_tile(wall,x,y)
end

function swap_tile(x,y)
 tile=mget(x,y)
 mset(x,y,tile+1)
end

function unswap_tile(x,y)
 tile=mget(x,y)
 mset(x,y,tile-1)
end

function get_key(x,y)
 p.keys+=1
 swap_tile(x,y)
 sfx(1)
end

function open_door(x,y)
 p.keys-=1
 swap_tile(x,y)
 sfx(2)
end
-->8
--player code

function make_player()
 p={}
 p.x=1
 p.y=8
 p.sprite=16
 p.keys=0
 p.tool=tool_types.none
end

function give_player_tool(tool)
 p.tool=tool 
 if tool==tool_types.none then
  p.sprite=16
 elseif tool==tool_types.x then
  p.sprite=128
 elseif tool==tool_types.y then
  p.sprite=129
 elseif tool==tool_types.z then
  p.sprite=130
 elseif tool==tool_types.h then
  p.sprite=131
--  elseif tool==tool_types.s then
--   p.sprite=132
--  elseif tool==tool_types.t then
--   p.sprite=133
 elseif tool==tool_types.ctrl then
  p.sprite=134
 end
end

function draw_player()
 spr(p.sprite,p.x*8,p.y*8)
end

function move_player()
 newx=p.x
 newy=p.y
 
 if (btnp(⬅️)) newx-=1
 if (btnp(➡️)) newx+=1
 if (btnp(⬆️)) newy-=1
 if (btnp(⬇️)) newy+=1
 
 interact(newx,newy)
 
 if (can_move(newx,newy)) then
  p.x=mid(0,newx,127)
  p.y=mid(0,newy,63)

  update_sel_circ_info()
 else
  sfx(0)
 end
end

function interact(x,y)
 if (is_tile(text,x,y)) then
  active_text=get_text(x,y)
 end

 if (is_tile(key,x,y)) then
   get_key(x,y)
 elseif (is_tile(door,x,y) and p.keys>0) then
   open_door(x,y)
 end
end
-->8
--inventory code

function show_inventory()
 invx=mapx*8+40
 invy=mapy*8+8
 
 rectfill(invx,invy,invx+48,invy+24,0)
 print("inventory",invx+7,invy+4,7)
 --print("keys "..p.keys,invx+12,invy+14,9)

 local qc = quantumcircuit()
 qc.set_registers(2)
 
 qc.h(0)
 qc.cx(0,1)
 
 
 
 local meas = quantumcircuit()
 meas.set_registers(2,2)
 
 meas.measure(0,0)
 meas.measure(1,1)

 qc.add_circuit(meas)
 
 result = simulate(qc,"counts",1)
 
end


-->8
--animation code

function toggle_tiles()
 for x=mapx,mapx+15 do
  for y=mapy,mapy+7 do
   if (is_tile(anim1,x,y)) then
    swap_tile(x,y)
    sfx(3)
   elseif (is_tile(anim2,x,y)) then
    unswap_tile(x,y)
    sfx(3)
   end
  end
 end
end
-->8
--win/lose code

function check_win_lose()
 if (is_tile(win,p.x,p.y)) then
  game_win=true
  game_over=true
 elseif (is_tile(lose,p.x,p.y)) then
  game_win=false
  game_over=true
 end
end

function draw_win_lose()
 camera()
 if (game_win) then
  print("★ you win! ★",37,64,7)
 else 
  print("game over! :(",37,64,7)
 end
 print("press ❎ to play again",20,72,5)
end

--text code

function text_setup()
 texts={}
 add_text(1,1,"first sign!")
 add_text(12,1,"oh, look!\na sign!")
end

function add_text(x,y,message)
 texts[x+y*128]=message
end

function get_text(x,y)
 return texts[x+y*128]
end

function draw_text()
 if (active_text) then
  textx=mapx*8+4
  texty=mapy*8+48
  
  rectfill(textx,texty,textx+119,texty+31,7)
  print(active_text,textx+4,texty+4,1)
  print("🅾️ to close",textx+4,texty+23,6)
 end
 
 if (btnp(🅾️)) active_text=nil
end
-->8
--circuit code
spr_tile={}
spr_tile.q=4
spr_tile.ket_0=38
spr_tile.ket_00=6

node_types={
 empty=72,
 iden=0,
 x=66,
 y=68,
 z=70,
 s=4,
 sdg=5,
 t=6,
 tdg=7,
 h=64,
 swap=9,
 --b=10
 ctrl=96,
 trace=12,
 meas=104
}

node_tiles={
  empty=72,
  x=66,
  low_not=102,
  high_not=100,
  y=68,
  z=70,
  h=64,
  low_ctrl=98,
  high_ctrl=96
}

tool_types={
 none=0, 
 x=1,
 y=2,
 z=3,
 h=4, 
 s=5, 
 t=6,
 ctrl=7 
}

-----begin qbcirc------
qbcirc={}

function qbcirc()
 local c={}
 c._nodes={}
 --c._nrows=0
 --c._ncols=0

 local function new(nrows,ncols)
  c._nrows=nrows or 2
  c._ncols=ncols or 4
  c._dirty=true
  for ri = 1, c._nrows do
   local row = {}
   c._nodes[ri] = row
   for ci = 1, c._ncols do
    local nd=qbnode()
    nd.new(node_types.empty)
    row[ci]=nd
   end
  end
 end 
 c.new=new


 function c.prt()
  for ri=1, c._nrows do
   local rowstr=""
   for ci=1, c._ncols do
    rowstr=rowstr..c._nodes[ri][ci].get_node_type()..","
   end
   printh(rowstr)
  end
 end

 function c.nrows()
  return c._nrows
 end

 function c.ncols()
  return c._ncols
 end

 --q pos?
 function c.set_pos(mx,my)
  c._mx=mx
  c._my=my
 end

 --q pos?
 function c.get_pos()
  return c._mx,c._my
 end

 function c.get_nodes()
  return c._nodes
 end

 function c.get_nodes_in_col(col_n)
  local col={}
  for row=1, c._nrows do
   col[row]=c._nodes[row][col_n]
  end
  --printh("#col:"..#col)
  return col
 end

 function c.set_node(row_n,
   col_n,grid_node)
  if row_n<=0 or row_n>c._nrows
    or col_n<=0 or col_n>c._ncols then
   return
  end 
  
  local node=qbnode()
  node.new(grid_node.get_node_type(),
    grid_node.get_rads(),
    grid_node.get_ctrla(),
    grid_node.get_ctrlb(),
    grid_node.get_swap())
  c._nodes[row_n][col_n]=node
 end

 function c.get_node(row_n,col_n)
  return c._nodes[row_n][col_n]
 end

 function c.get_node_gate_part(row_n,col_n)
  local req_node=c._nodes[row_n][col_n]
  if req_node and
    req_node.get_node_type()
    ~= node_types.empty then
   return req_node.get_node_type()
  else
   local nodes_col=
     c.get_nodes_in_col(col_n)
   for idx=1,c._nrows do
    if idx~=row_n then
     local oth_node=nodes_col[idx]
     if oth_node then
      if oth_node.get_ctrla()==
        row_n or
        oth_node.get_ctrlb()==
        row_n then
       return node_types.ctrl
      elseif oth_node.get_swap()
          ==row_n then
       return node_types.swap
      end
     end
    end
   end
   return node_types.empty
  end
 end

 function c.get_ctrl_gate_row(
   ctrl_row_n,col_n)
  local gate_row_n=0
  local nodes_col=
    c.get_nodes_in_col(col_n)
  for ri=1, c._nrows do
   if ri~=ctrl_row_n then
    local oth_node=nodes_col[ri]
    --printh("get_ctrl_gate_row, ri:"..ri..", oth_node:"..oth_node.get_node_type()) 
    if oth_node then
     if oth_node.get_ctrla()==
        ctrl_row_n then
      gate_row_n=ri
      --printh("found gate")
     end
    end
   end
  end
  return gate_row_n
 end

 function c.comp_circ()
  local qc = quantumcircuit()
  qc.set_registers(c._nrows)

  for ri=1,c._nrows do
   for ci=1,c._ncols do
    local nd=c._nodes[ri][ci]
    if nd then
     --printh("node is present"..nd.get_node_type())
     if nd.get_node_type()==
       node_types.iden then
      --todo
     elseif nd.get_node_type()==
       node_types.x then
      if nd.get_rads()==0 then
       if nd.get_ctrla()>0 then
        if nd.get_ctrlb()>0 then
         --todo: toffoli
        else
         printh("make cx")
         qc.cx(nd.get_ctrla()-1,
           ri-1)
        end
       else
        printh("make x")
        qc.x(ri-1)
       end
      else
       qc.rx(nd.get_rads(),ri-1)
      end
     elseif nd.get_node_type()==
       node_types.y then
      if nd.get_rads()==0 then
       if nd.get_ctrla()>0 then
        --todo ctrl-y
       else
        qc.y(ri-1)
       end
      else
       qc.ry(nd.get_rads(),ri-1)
      end
     elseif nd.get_node_type()==
       node_types.z then
      if nd.get_rads()==0 then
       if nd.get_ctrla()>0 then
        --todo ctrl-z
       else
        qc.z(ri-1)
       end
      else
       if nd.get_ctrla()>0 then
        --todo crz
       else
        qc.rz(nd.get_rads(),ri-1)
       end
      end
     elseif nd.get_node_type()==
       node_types.s then
      qc.rz(math.pi/4,ri-1)
     elseif nd.get_node_type()==
       node_types.t then
      qc.rz(math.pi/8,ri-1)
     elseif nd.get_node_type()==
       node_types.sdg then
      qc.rz(-math.pi/4,ri-1)
     elseif nd.get_node_type()==
       node_types.tdg then
      qc.rz(-math.pi/8,ri-1)
     elseif nd.get_node_type()==
       node_types.h then
      if nd.get_ctrla()>0 then
       --todo ctrl-h
      else
       --printh("i found an h")
       qc.h(ri-1)
      end
     elseif nd.get_node_type()==
       node_types.swap then
      if nd.get_ctrla()>0 then
       --todo ctrl-swap
      else
       qc.swap(ri-1,
         nd.get_swap()-1)
      end
     end
    end
   end
  end
  return qc
 end

 function c.set_dirty(flg)
  c._dirty=flg
 end
 
 function c.is_dirty()
  return c._dirty
 end

 return c
end
-----end qbcirc------


-----begin qbnode------
function qbnode()
 local n={}

 local function new(node_type,
   rads,ctrla,ctrlb,swap)
  n._node_type=node_type
  n._rads=rads or 0
  n._ctrla=ctrla or 0
  n._ctrlb=ctrlb or 0
  n._swap=swap or 0
 end
 n.new=new

 function n.get_node_type()
  return n._node_type
 end

 function n.get_rads()
  return n._rads
 end

 function n.get_ctrla()
  return n._ctrla
 end

 function n.set_ctrla(row)
  n._ctrla=row
 end

 function n.get_ctrlb()
  return n._ctrlb
 end

 function n.get_swap()
  return n._swap
 end
 return n
end
-----end qbnode------


-----begin misc functions------
function build_popup_menu()
 local function tool_h()
  give_player_tool(tool_types.h)
 end
 menuitem(1, "h gate", tool_h) 

 local function tool_x()
  give_player_tool(tool_types.x)
 end
 menuitem(2, "x gate", tool_x) 

 local function tool_z()
  give_player_tool(tool_types.z)
 end
 menuitem(3, "z gate", tool_z) 

 local function tool_ctrl()
  give_player_tool(tool_types.ctrl)
 end
 menuitem(4, "ctrl tool", tool_ctrl) 

 local function no_tool()
  give_player_tool(tool_types.none)
 end
 menuitem(5, "no tool", no_tool) 

 --  local function tool_y()
--   give_player_tool(tool_types.y)
--  end
--  menuitem(6, "y gate", tool_y) 

--  local function tool_s()
--   give_player_tool(tool_types.s)
--  end
--  menuitem(7, "s gate", tool_s) 

--  local function tool_t()
--   give_player_tool(tool_types.t)
--  end
--  menuitem(8, "t gate", tool_t) 

end

function make_circs()
 local circ=qbcirc()

--test circuit 1
 circ.new(2,4)
 local nd=qbnode()
--  nd.new(node_types.h,0,0)
--  circ.set_node(1,1,nd)
--  nd.new(node_types.z,0,0)
--  circ.set_node(1,2,nd)
 local qc=circ.comp_circ()

 circ.set_pos(2,10)
 local tx,ty=circ.get_pos()
 --printh("tx:"..tx.." ty:"..ty)
 circ.prt()
 qbcircs[1]=circ

 --test circuit 2
 circ=qbcirc()
 circ.new(3,5)
 circ.set_pos(18,10)
 local tx,ty=circ.get_pos()
 --printh("tx:"..tx.." ty:"..ty)

 circ.prt()
 circ.comp_circ()
 qbcircs[2]=circ
end

function compute_statevector(res)
  local statevector = {}
  printh("statevector:")
  for idx, amp in pairs(res) do
    statevector[idx] = complex.new(
      amp[1],amp[2])   
    printh(statevector[idx].r.."+"..statevector[idx].i.."i")
  end
  sel_sv=statevector  
end

-----begin misc functions------


-----begin handle player input------
function hnd_input()
 if p.tool==tool_types.x then
  hnd_inp_x()
 elseif p.tool==tool_types.y then  
  hnd_inp_y()
 elseif p.tool==tool_types.z then  
  hnd_inp_z()
 elseif p.tool==tool_types.h then  
  hnd_inp_h()
 elseif p.tool==tool_types.ctrl then  
  hnd_inp_ctrl()
 elseif p.tool==tool_types.none then  
  hnd_inp_del()
 end
end

function update_sel_circ_info()
 for circ_idx=1, #qbcircs do
  local circ=qbcircs[circ_idx]
  local cpx, cpy = circ.get_pos()
  if newx>=cpx+2 and 
    newx<cpx+(circ.ncols()+1)*2 and
    newy<=cpy-1 and
    newy>cpy-(circ.nrows())*2-1 then
   sel_circ_idx=circ_idx
   sel_circ_row=circ.nrows()-flr((cpy-newy-1)/2)
   sel_circ_col=flr((newx-cpx)/2) 
   sel_circ=circ
   return
  end
  sel_circ_idx=0
  sel_circ_row=0
  sel_circ_col=0
  sel_circ=nil
 end
end

function get_sel_node_gate_part()
 if sel_circ then
  return sel_circ.get_node_gate_part(
    sel_circ_row,sel_circ_col)
 else
  return node_types.empty
 end 
end

function place_ctrl(gate_row,cand_row)
  if cand_row<1 or 
      cand_row>sel_circ.nrows() then
    return 0    
  end
  cand_row_gate_part= 
    sel_circ.get_node_gate_part(
      cand_row,sel_circ_col)
  if cand_row_gate_part==
      node_types.empty or
      cand_row_gate_part==
      node_types.trace then
    nd=sel_circ.get_node(
        gate_row,sel_circ_col)
    nd.set_ctrla(cand_row)
    sel_circ.set_node(gate_row,
        sel_circ_col,nd)
    local emp_nd=qbnode()
    emp_nd.new(node_types.empty)
    sel_circ.set_node(cand_row,
        sel_circ_col,emp_nd)
        printh("placed ctrl on row:"..cand_row)    
    sel_circ.set_dirty(true)
    return cand_row
  else
    printh("can't place ctrl on row:"..cand_row)
  end
end

function hnd_inp_x()
 local sngp=get_sel_node_gate_part()
 if sngp==node_types.empty then
  local nd=qbnode()
  nd.new(node_types.x,0,0)
  if sel_circ then
   sel_circ.set_node(sel_circ_row,
                  sel_circ_col,nd)
   sel_circ.set_dirty(true)
  end
 end
end

function hnd_inp_y()
 local sngp=get_sel_node_gate_part()
 if sngp==node_types.empty then
  local nd=qbnode()
  nd.new(node_types.y,0,0)
  if sel_circ then
   sel_circ.set_node(sel_circ_row,
                  sel_circ_col,nd)
   sel_circ.set_dirty(true)
  end
 end
end 

function hnd_inp_z()
 local sngp=get_sel_node_gate_part()
 if sngp==node_types.empty then
  local nd=qbnode()
  nd.new(node_types.z,0,0)
  if sel_circ then
   sel_circ.set_node(sel_circ_row,
                  sel_circ_col,nd)
   sel_circ.set_dirty(true)
  end
 end
end 

function hnd_inp_h()
 local sngp=get_sel_node_gate_part()
 if sngp==node_types.empty then
  local nd=qbnode()
  nd.new(node_types.h,0,0)
  if sel_circ then
   sel_circ.set_node(sel_circ_row,
                  sel_circ_col,nd)
   sel_circ.set_dirty(true)
  end
 end
end 

function hnd_inp_ctrl()
  local sngp=get_sel_node_gate_part()
  if sngp==node_types.x or
      sngp==node_types.y or 
      sngp==node_types.z or
      sngp==node_types.h then
    local nd=sel_circ.get_node(
      sel_circ_row,sel_circ_col)
    if nd.get_ctrla()>0 then
      o_ctrla=nd.get_ctrla()
      nd.set_ctrla(0)
      sel_circ.set_node(
        sel_circ_row,sel_circ_col,nd)
      --todo: remove trace nodes
    else
      if sel_circ_row>0 then
        if place_ctrl(sel_circ_row, 
            sel_circ_row-1)==0 then
          if sel_circ_row<sel_circ.nrows() then
            if place_ctrl(sel_circ_row, 
              sel_circ_row+1)==0 then
              printh("can't place ctrl")  
            end
          end
        end
      end
    end
  end
end 
  
--todo: add logic for del ctrls
function hnd_inp_del()
 local sngp=get_sel_node_gate_part()
 if sngp==node_types.x or
   sngp==node_types.y or 
   sngp==node_types.z or
   sngp==node_types.h then
  local nd=qbnode()
  nd.new(node_types.empty,0,0)
  if sel_circ then
   sel_circ.set_node(sel_circ_row,
                  sel_circ_col,nd)
   sel_circ.set_dirty(true)
  end
 end
end 
-----end handle player input------


function draw_circs()
 for circ_idx=1,#qbcircs do
  local qbcirc=qbcircs[circ_idx]
  local mx,my=qbcirc.get_pos()

  spr(spr_tile.q,mx*8,my*8,2,2)

  local nds=qbcirc.get_nodes()

  for ri = 1, #nds do
   --spr(spr_tile.ket_0+(#nds[ri]-ci)*2,
   spr(spr_tile.ket_0+(#nds-ri)*2,
     mx*8,
     (my-((qbcirc.nrows()+1)*2)+ri*2)*8,2,2)

   for ci = 1, #nds[ri] do
    spr(spr_tile.ket_00+(ci-1)*2,
      (mx+ci*2)*8,
      (my+2)*8,2,2)

    local nd=nds[ri][ci]
    local nt=qbcirc.get_node_gate_part(
      ri,ci)
    --local nt=nd.get_node_type()
    local tile=node_tiles.empty
    if nt==node_types.x then
      if nd.get_ctrla()>0 then
        if ri>nd.get_ctrla() then
          tile=node_tiles.low_not
        else  
          tile=node_tiles.high_not
        end
      else
        tile=node_tiles.x
      end
    elseif nt==node_types.y then
      tile=node_tiles.y
    elseif nt==node_types.z then
      tile=node_tiles.z
    elseif nt==node_types.h then
      tile=node_tiles.h
    elseif nt==node_types.ctrl then
      if ri>qbcirc.get_ctrl_gate_row(
        ri,ci) then
        tile=node_tiles.low_ctrl
      else  
        tile=node_tiles.high_ctrl
      end
    end
      
    spr(tile,
      (mx+ci*2)*8,
      (my-((qbcirc.nrows()+1)*2)+ri*2)*8,2,2)
   end
  end
 end
end

function draw_probs(res)
  if not sel_circ or not sel_sv then
    return
  end

  local liq_levs=7
  local pi_rads=4
  local empty_liq_tile=224
  local first_liq_tile=192
  local first_phase_tile=160
  local mx,my=sel_circ.get_pos()
  local p4_rads_offset=0
  local p4_rads_offset_set=false

  for col_num=1,min(#sel_sv, sel_circ.ncols()) do
    local amp = sel_sv[col_num]
    --printh(amp.r.."+"..amp.i.."i")
    local phase_rad = 
      (complex.polar_radians(amp) + 
      math.pi*2)%(math.pi*2)
    --printh("phase_rad: "..phase_rad)
    local p4_rads=0
    local thresh=0.0001
    if abs(phase_rad-0)>thresh and
        abs(phase_rad-math.pi*2)>thresh then
      p4_rads = flr(phase_rad*pi_rads/math.pi+0.5)
    end
    --printh("phase_rad: "..phase_rad..", p4_rads: "..p4_rads)   
    if p4_rads<0 then
      p4_rads=0
    elseif p4_rads>pi_rads*2 then
      p4_rads=pi_rads*2
    end

    local prob=(complex.abs(sel_sv[col_num]))^2
    local scaled_prob=flr(prob*liq_levs)
    
    --remove global phase for any basis states with prob
    if prob>0 and not p4_rads_offset_set then
      p4_rads_offset=-p4_rads
      p4_rads_offset_set=true
    end
    if prob>0 then
      p4_rads=(p4_rads+p4_rads_offset+pi_rads*2)%(pi_rads*2)
    end

    local spr_prob_tile=empty_liq_tile
    if scaled_prob>0 then
      spr_prob_tile=first_liq_tile+(scaled_prob)*2
    end

    spr(spr_prob_tile,
      (mx+col_num*2)*8,
      my*8,2,2)

    local spr_phase_tile=
      first_phase_tile+p4_rads*2

    spr(spr_phase_tile,
      (mx+col_num*2)*8,
      my*8,2,2)
      

  end
    

end

----begin complex module----
function create_complex()

  local complex = {}  -- the module

  -- creates a new complex number
  local function new (r, i)
      return {r=r, i=i}
  end

  complex.new = new        -- add 'new' to the module

  -- constant 'i'
  complex.i = new(0, 1)

  function complex.add (c1, c2)
      return new(c1.r + c2.r, c1.i + c2.i)
  end

  function complex.sub (c1, c2)
      return new(c1.r - c2.r, c1.i - c2.i)
  end

  function complex.mul (c1, c2)
      return new(c1.r*c2.r - c1.i*c2.i, c1.r*c2.i + c1.i*c2.r)
  end

  local function inv (c)
      local n = c.r^2 + c.i^2
      return new(c.r/n, -c.i/n)
  end

  function complex.div (c1, c2)
      return complex.mul(c1, inv(c2))
  end

  function complex.nearly_equals (c1, c2)
      return abs(c1.r - c2.r) < 0.001 and
              abs(c1.i - c2.i) < 0.001
  end

  function complex.abs (c)
      return sqrt(c.r^2 + c.i^2)
  end

  function complex.tostring (c)
      return string.format("(%g,%g)", c.r, c.i)
  end

  -- function complex.polar_radians(c)
  --     return atan2( c.i, c.r )
  -- end

  --modified for pico atan2 behavior
  function complex.polar_radians(c)
    local norm_atan2=0
    if c.r~=0 or c.i~=0 then
      local pico_atan2=atan2( c.r, -c.i )
      norm_atan2=pico_atan2*2
    end
    return norm_atan2 * math.pi
  end

  return complex

end
complex = create_complex()
----end complex module----

-->8
-- this code is part of qiskit.
--
-- copyright ibm 2020

-- custom math table for compatibility with the pico8

math = {}
math.pi = 3.14159
math.max = max
math.sqrt = sqrt
math.floor = flr
function math.random()
  return rnd(1)
end
function math.cos(theta)
  return cos(theta/(2*math.pi))
end
function math.sin(theta)
  return -sin(theta/(2*math.pi))
end
function math.randomseed(time)
end
os = {}
function os.time()
end

math.randomseed(os.time())

function quantumcircuit ()

  local qc = {}

  local function set_registers (n,m)
    qc._n = n
    qc._m = m or 0
  end
  qc.set_registers = set_registers

  qc.data = {}

  function qc.initialize (ket)
    ket_copy = {}
    for j, amp in pairs(ket) do
      if type(amp)=="number" then
        ket_copy[j] = {amp, 0}
      else
        ket_copy[j] = {amp[0], amp[1]}
      end
    end
    qc.data = {{'init',ket_copy}}
  end

  function qc.add_circuit (qc2)
    qc._n = math.max(qc._n,qc2._n)
    qc._m = math.max(qc._m,qc2._m)
    for g, gate in pairs(qc2.data) do
      qc.data[#qc.data+1] = ( gate )    
    end
  end
      
  function qc.x (q)
    qc.data[#qc.data+1] = ( {'x',q} )
  end

  function qc.rx (theta,q)
    qc.data[#qc.data+1] = ( {'rx',theta,q} )
  end

  function qc.h (q)
    qc.data[#qc.data+1] = ( {'h',q} )
  end

  function qc.cx (s,t)
    qc.data[#qc.data+1] = ( {'cx',s,t} )
  end

  function qc.measure (q,b)
    qc.data[#qc.data+1] = ( {'m',q,b} )
  end

  function qc.rz (theta,q)
    qc.h(q)
    qc.rx(theta,q)
    qc.h(q)
  end

  function qc.ry (theta,q)
    qc.rx(math.pi/2,q)
    qc.rz(theta,q)
    qc.rx(-math.pi/2,q)
  end

  function qc.z (q)
    qc.rz(math.pi,q)
  end

  function qc.y (q)
    qc.z(q)
    qc.x(q)
  end

  return qc

end




function simulate (qc, get, shots)

  if not shots then
    shots = 1024
  end

  function as_bits (num,bits)
    -- returns num converted to a bitstring of length bits
    -- adapted from https://stackoverflow.com/a/9080080/1225661
    local bitstring = {}
    for index = bits, 1, -1 do
        b = num - math.floor(num/2)*2
        num = math.floor((num - b) / 2)
        bitstring[index] = b
    end
    return bitstring
  end

  function get_out (j)
    raw_out = as_bits(j-1,qc._n)
    out = ""
    for b=0,qc._m-1 do
      if output_map[b] then
        out = raw_out[qc._n-output_map[b]]..out
      end
    end
    return out
  end


  ket = {}
  for j=1,2^qc._n do
    ket[j] = {0,0}
  end
  ket[1] = {1,0}

  output_map = {}

  for g, gate in pairs(qc.data) do

    if gate[1]=='init' then

      for j, amp in pairs(gate[2]) do
          ket[j] = {amp[1], amp[2]}
      end

    elseif gate[1]=='m' then

      output_map[gate[3]] = gate[2]

    elseif gate[1]=="x" or gate[1]=="rx" or gate[1]=="h" then

      j = gate[#gate]

      for i0=0,2^j-1 do
        for i1=0,2^(qc._n-j-1)-1 do
          b1=i0+2^(j+1)*i1 + 1
          b2=b1+2^j

          e = {{ket[b1][1],ket[b1][2]},{ket[b2][1],ket[b2][2]}}

          if gate[1]=="x" then
            ket[b1] = e[2]
            ket[b2] = e[1]
          elseif gate[1]=="rx" then
            theta = gate[2]
            ket[b1][1] = e[1][1]*math.cos(theta/2)+e[2][2]*math.sin(theta/2)
            ket[b1][2] = e[1][2]*math.cos(theta/2)-e[2][1]*math.sin(theta/2)
            ket[b2][1] = e[2][1]*math.cos(theta/2)+e[1][2]*math.sin(theta/2)
            ket[b2][2] = e[2][2]*math.cos(theta/2)-e[1][1]*math.sin(theta/2)
          elseif gate[1]=="h" then
            for k=1,2 do
              ket[b1][k] = (e[1][k] + e[2][k])/math.sqrt(2)
              ket[b2][k] = (e[1][k] - e[2][k])/math.sqrt(2)
            end
          end

        end
      end

    elseif gate[1]=="cx" then

      s = gate[2]
      t = gate[3]

      if s>t then
        h = s
        l = t
      else
        h = t
        l = s
      end

      for i0=0,2^l-1 do
        for i1=0,2^(h-l-1)-1 do
          for i2=0,2^(qc._n-h-1)-1 do
            b1 = i0 + 2^(l+1)*i1 + 2^(h+1)*i2 + 2^s + 1
            b2 = b1 + 2^t
            e = {{ket[b1][1],ket[b1][2]},{ket[b2][1],ket[b2][2]}}
            ket[b1] = e[2]
            ket[b2] = e[1]
          end
        end
      end

    end

  end

  if get=="statevector" then
    return ket
  else

    probs = {}
    for j,amp in pairs(ket) do
      probs[j] = amp[1]^2 + amp[2]^2
    end

    if get=="fast counts" then

      c = {}
      for j,p in pairs(probs) do
        out = get_out(j)
        if c[out] then
          c[out] = c[out] + probs[j]*shots
        else
          if out then -- in case of pico8 weirdness
            c[out] = probs[j]*shots
          end
        end
      end
      return c

    else

      m = {}
      for s=1,shots do
        cumu = 0
        un = true
        r = math.random()
        for j,p in pairs(probs) do
          cumu = cumu + p
          if r<cumu and un then
            m[s] = get_out(j)
            un = false
          end
        end
      end

      if get=="memory" then
        return m

      elseif get=="counts" then
        c = {}
        for s=1,shots do
          if c[m[s]] then
            c[m[s]] = c[m[s]] + 1
          else
            if m[s] then -- in case of pico8 weirdness
              c[m[s]] = 1
            else
              if c["error"] then
                c["error"] = c["error"]+1
              else
                c["error"] = 1
              end
            end
          end
        end
        return c

      end

    end

  end

end
__gfx__
000000003333333376767767677767671111111111111111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000
00000000333333f365555555555555571111111111111111f66666666666666ff66666666666666ff66666666666666ff66666666666666f0000000000000000
007007003f33333375555555555555561111177777111111f66666666666666ff66666666666666ff66666666666666ff66666666666666f0000000000000000
000770003333f3336ccccccccc7cccc71111771117711111f16666666616666ff16666666616666ff16666666616666ff16666666616666f0000000000000000
00077000333333337ccc7cccccc7ccc61117711111771111f16666666661666ff16666666661666ff16666666661666ff16666666661666f0000000000000000
00700700333333f37cccc7cccccc0cc71117111111171111f16eee6aaa66166ff16eee66a666166ff166e66aaa66166ff166e666a666166f0000000000000000
00000000333f33336cccccccccccc0c61117111111171111f16e6e6a6a66606ff16e6e6aa666616ff16ee66a6a66616ff16ee66aa666616f0000000000000000
00000000333333337cccccc0000000071117111111171111f16e6e6a6a66661ff16e6e66a666661ff166e66a6a66661ff166e666a666661f0000000000000000
00040000000000007cccccccccccc0c71117111111171111f16e6e6a6a66661ff16e6e66a666661ff166e66a6a66661ff166e666a666661f4444444466666666
00040000000000006ccccccccccc0cc61117111111171111f16e6e6a6a66616ff16e6e66a666616ff166e66a6a66616ff166e666a666616f4ffffff166888866
09999900000000007ccccccccc7cccc71117711111771111f16eee6aaa66166ff16eee6aaa66166ff16eee6aaa66166ff16eee6aaa66166f4f1ff1f168666686
90999090000000006ccc7cccccc7ccc61111771117711111f16666666661666ff16666666661666ff16666666661666ff16666666661666f4f1f1ff168688686
40999040000000007cccc7ccccccccc71111177777111111f16666666616666ff16666666616666ff16666666616666ff16666666616666f4ffffff168688686
00aaa000000000007cccccccccccccc71111111711111111f66666666666666ff66666666666666ff66666666666666ff66666666666666f4111111168666686
00a0a000000000006cccccccccccccc61111111777111111f66666666666666ff66666666666666ff66666666666666ff66666666666666f3334133366888866
00a0a0000000000077677677676776771111111111111111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3334133366666666
33333333333333337676776767776767999999999999999966666666666666666666666666666666666666666666666600000000000000003333333333333333
99933333333333f36555555555555557999999999999999966666666666666666666666666666666666666666666666600000000000000003633363330333033
9a9999993f3333337555555555555556999997777799999966666666666666666666666666666666666666666666666600000000000000000603060305030503
939aa9a93333f3336555555555755557999977999779999966166661666666666616666166666666661666616666666600000000000000003033303330333033
99933a3a333333337555755555575556999779999977999966166666166666666616666616666666661666661666666600000000000000003333333333333333
aaa33333333333f3755557555555055799979999999799996616eee6616666666616aaa6616666666616bbb66166666600000000000000003633363330333033
33333333333f3333655555555555505699979999999799996616e6e6661666666616a6a6661666666616b6b66616666600000000000000000603060305030503
3333333333333333755555500000000799979999999799996616e6e6666166666616a6a6666166666616b6b66661666600000000000000003033303330333033
4a4444a44a4aa4a4755555555555505799979999999799996616e6e6666166666616a6a6666166666616b6b66661666600000000000000005555555555555555
4a4444a405099151655555555555055699979999999799996616e6e6661666666616a6a6661666666616b6b66616666600000000000000005554455555500555
4a4444a411111111755555555575555799977999997799996616eee6616666666616aaa6616666666616bbb66166666600000000000000005444444550000005
4a4444a4111111116555755555575556999977999779999966166666166666666616666616666666661666661666666600000000000000005114444550000005
aaa99aaa151111517555575555555557999997777799999966166661666666666616666166666666661666616666666600000000000000005444444550000005
191991914a4444a47cccccccccccccc7999999979999999966666666666666666666666666666666666666666666666600000000000000005444464550000005
4a4444a44a4444a46cccccccccccccc6999999977799999966666666666666666666666666666666666666666666666600000000000000005114444550000005
4a4444a44a4444a47767767767677677999999999999999966666666666666666666666666666666666666666666666600000000000000005444444550000005
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777770000000000000000
71111111111111177111111111111117711111111111111771111111111111177777777777777777711111111111111771111111111111170000000000000000
71777777777777177177777777777717717777777777771771777777777777177777777777777777717777777777771771777777777777170000000000000000
71777777777777177177777777777717717777777777771771777777777777177777777777777777717777777777771771777777777777170000000000000000
71777177771777177177717777177717717717777717771771777111111777177777777777777777717777111177771771771111111777170000000000000000
71777177771777177177717777177717717771777177771771777777771777177777777777777777717771777717771771777771777777170000000000000000
71777177771777177177771771777717717777171777771771777777717777177777777177777777717771777777771771777771777777170000000000000000
11777111111777111177777117777711117777717777771111777777177777111111111111111111117777117777771111777771777777110000000000000000
71777177771777177177777117777717717777707777771771777771777777177777777177777777717777771177771771777771777777170000000000000000
71777177771777177177771771177717717777707777771771777717777777177777777777777777717777777717771771777771777777170000000000000000
71777177771777177177717777177717717777707777771771777177777777177777777777777777717771777717771771777771777777170000000000000000
71777177771777177177717777177717717777707777771771777111111777177777777777777777717777111177771771777771777777170000000000000000
71777777777777177177777777777717717777777777771771777777777777177777777777777777717777777777771771777777777777170000000000000000
71777777777777177177777777777717717777777777771771777777777777177777777777777777717777777777771771777777777777170000000000000000
71111111111111177111111111111117711111111111111771111111111111177777777777777777711111111111111771111111111111170000000000000000
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777770000000000000000
77777777777777777777777177777777777777777777777777777771777777777777777777777777000000000000000000000000000000000000000000000000
77777777777777777777777177777777777777777777777777777771777777777111111111111117000000000000000000000000000000000000000000000000
77777777777777777777777177777777777777777777777777777771777777777177777777777717000000000000000000000000000000000000000000000000
77777777777777777777777177777777777777777777777777777771777777777177777777777717000000000000000000000000000000000000000000000000
77777777777777777777777177777777777777111777777777777711177777777177777777777717000000000000000000000000000000000000000000000000
77777711177777777777771117777777777771717177777777777171717777777177777777717717000000000000000000000000000000000000000000000000
77777111117777777777711111777777777717717717777777771771771777777177775115177717000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111177607771167711000000000000000000000000000000000000000000000000
77777111117777777777711111777777777717717717777777771771771777777177177717717717000000000000000000000000000000000000000000000000
77777711177777777777771117777777777771717177777777777171717777777175777177775717000000000000000000000000000000000000000000000000
77777771777777777777777777777777777777111777777777777711177777777171777777771717000000000000000000000000000000000000000000000000
77777771777777777777777777777777777777717777777777777777777777777177777777777717000000000000000000000000000000000000000000000000
77777771777777777777777777777777777777717777777777777777777777777177777777777717000000000000000000000000000000000000000000000000
77777771777777777777777777777777777777717777777777777777777777777177777777777717000000000000000000000000000000000000000000000000
77777771777777777777777777777777777777717777777777777777777777777111111111111117000000000000000000000000000000000000000000000000
77777771777777777777777777777777777777717777777777777777777777777777777777777777000000000000000000000000000000000000000000000000
00077777000777770007777700077777000777770007777700077777101010101010101010101010101010101010101010101010101010101010101010101010
00071717000717170007111700071717000771170007111700071117101010101010101010101010101010101010101010101010101010101010101010101010
09971717099717170997771709971717099717770997717709971117101010101010101010101010101010101010101010101010101010101010101010101010
90977177909711179097717790971117909711179097717790971117101010101010101010101010101010101010101010101010101010101010101010101010
40971717409777174097177740971717409777174097717740977177101010101010101010101010101010101010101010101010101010101010101010101010
00a7171700a7111700a7111700a7171700a7117700a7717700a77177101010101010101010101010101010101010101010101010101010101010101010101010
00a7777700a7777700a7777700a7777700a7777700a7777700a77777101010101010101010101010101010101010101010101010101010101010101010101010
00a0a00000a0a00000a0a00000a0a00000a0a00000a0a00000a0a000101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000088800000000888000000000888000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000008800000008080800000000880000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000080800000000080000000000808000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000080000000000000800000000000080000000000000800000000000000000000000000000000000000000000000000000000000000000000000000
00000000000008000000000008000000000000080000000000000080000000000008000000000000000000000000000000000000000000000000000000000000
00000008888888800000000080000000000000080000000000000008000000000080000000000000000000008000000000000008000000000000000800000000
00000000000008000000000800000000000000080000000000000000800000000888888880000000000000080000000000000008000000000000000080000000
00000000000080000000000000000000000000000000000000000000000000000080000000000000000000800000000000000008000000000000000008000000
00000000000000000000000000000000000000000000000000000000000000000008000000000000000008000000000000000008000000000000000000800000
00000000000000000000000000000000000000000000000000000000000000000000000000000000008080000000000000000008000000000000000000080800
00000000000000000000000000000000000000000000000000000000000000000000000000000000008800000000000000000808080000000000000000008800
00000000000000000000000000000000000000000000000000000000000000000000000000000000008880000000000000000088800000000000000000088800
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76767767677767677676776767776767767677676777676776767767677767677676776767776767767677676777676776767767677767677676776767776767
66666666666666676666666666666667666666666666666766666666666666676666666666666667666666666666666766666666666666676cccccccccccccc7
7666666666666666766666666666666676666666666666667666666666666666766666666666666676666666666666667cccccccccccccc67cccccccccccccc6
6666666666766667666666666676666766666666667666676666666666766667666666666676666766666666667666676ccccccccc7cccc76ccccccccc7cccc7
766676666667666676667666666766667666766666676666766676666667666676667666666766667ccc7cccccc7ccc67ccc7cccccc7ccc67ccc7cccccc7ccc6
766667666666666776666766666666677666676666666667766667666666666776666766666666677cccc7ccccccccc77cccc7ccccccccc77cccc7ccccccccc7
66666666666666666666666666666666666666666666666666666666666666666cccccccccccccc66cccccccccccccc66cccccccccccccc66cccccccccccccc6
76666666666666677666666666666667766666666666666776666666666666677cccccccccccccc77cccccccccccccc77cccccccccccccc77cccccccccccccc7
7666666666666667766666666666666776666666666666677cccccccccccccc77cccccccccccccc77cccccccccccccc77cccccccccccccc77cccccccccccccc7
6666666666666666666666666666666666666666666666666cccccccccccccc66cccccccccccccc66cccccccccccccc66cccccccccccccc66cccccccccccccc6
766666666676666776666666667666677ccccccccc7cccc77ccccccccc7cccc77ccccccccc7cccc77ccccccccc7cccc77ccccccccc7cccc77ccccccccc7cccc7
666676666667666666667666666766666ccc7cccccc7ccc66ccc7cccccc7ccc66ccc7cccccc7ccc66ccc7cccccc7ccc66ccc7cccccc7ccc66ccc7cccccc7ccc6
76666766666666677cccc7ccccccccc77cccc7ccccccccc77cccc7ccccccccc77cccc7ccccccccc77cccc7ccccccccc77cccc7ccccccccc77cccc7ccccccccc7
76666666666666677cccccccccccccc77cccccccccccccc77cccccccccccccc77cccccccccccccc77cccccccccccccc77cccccccccccccc77cccccccccccccc7
6cccccccccccccc66cccccccccccccc66cccccccccccccc66cccccccccccccc66cccccccccccccc66cccccccccccccc66cccccccccccccc66cccccccccccccc6
77677677676776777767767767677677776776776767767777677677676776777767767767677677776776776767767777677677676776777767767767677677
76767767677767670000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
66666666666666670000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
76666666666666660000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
66666666667666670000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
76667666666766660000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
76666766666666670000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
66666666666666660000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
76666666666666670000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
76666666666666670000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
66666666666666660000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
76666666667666670000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
66667666666766660000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
76666766666666670000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
76666666666666670000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
66666666666666660000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
77677677676776770000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
__label__
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
3f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333333
3333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333334a4444a433333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f34a4444a4333333f3
3f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333334a4444a43f333333
3333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3334a4444a43333f333
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333aaa99aaa33333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f319199191333333f3
333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f33334a4444a4333f3333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333334a4444a433333333
33333333333333336666666666666666777777777777777777777777777777777777777777777777777777777777777733333333333333333333333333333333
333333f3333333f366666666666666667000000000000007777777777777777777777777777777777000000000000007333333f330333033333333f3333333f3
3f3333333f333333666666666666666670777777777777077777777777777777777777777777777770777777777777073f333333050305033f3333333f333333
3333f3333333f333660666606666666670777777777777077777777777777777777777777777777770777777777777073333f333303330333333f3333333f333
33333333333333336606666606666666707770777707770777777777777777777777777777777777707777777777770733333333333333333333333333333333
333333f3333333f36606aaa6606666667077707777077707777777000777777777777777777777777077777777707707333333f330333033333333f3333333f3
333f3333333f33336606a6a6660666667077707777077707777770000077777777777770777777777077775005077707333f333305030503333f3333333f3333
33333333333333336606a6a666606666007770000007770000000000000000000000000000000000007760777006770033333333303330333333333333333333
33333333333333336606a6a666606666707770777707770777777000007777777777777077777777707707770770770733333333333333333333333355555555
333333f3333333f36606a6a6660666667077707777077707777777000777777777777777777777777075777077775707333333f330333033333333f355544555
3f3333333f3333336606aaa66066666670777077770777077777777077777777777777777777777770707777777707073f333333050305033f33333354444445
3333f3333333f333660666660666666670777077770777077777777077777777777777777777777770777777777777073333f333303330333333f33351144445
33333333333333336606666066666666707777777777770777777770777777777777777777777777707777777777770733333333333333333333333354444445
333333f3333333f366666666666666667077777777777707777777707777777777777777777777777077777777777707333333f330333033333333f354444645
333f3333333f333366666666666666667000000000000007777777707777777777777777777777777000000000000007333f333305030503333f333351144445
33333333333333336666666666666666777777777777777777777770777777777777777777777777777777777777777733333333303330333333333354444445
33333333333333336666666666666666777777777777777777777770777777777777777777777777777777777777777733333333333333333333333333333333
333333f3333333f366666666666666667777777777777777777777707777777777777777777777777000000000000007333333f336333633333333f3333333f3
3f3333333f333333666666666666666677777777777777777777777077777777777777777777777770777777777777073f333333060306033f3333333f333333
3333f3333333f333660666606666666677777777777777777777777077777777777777777777777770777777777777073333f333303330333333f3333333f333
33333333333333336606666606666666777777777777777777777700077777777777777777777777707777777777770733333333333333333333333333333333
333333f3333333f36606eee6606666667777777777777777777770707077777777777777777777777077777777707707333333f336333633333333f3333333f3
333f3333333f33336606e6e6660666667777777077777777777707707707777777777770777777777077775005077707333f333306030603333f3333333f3333
33333333333333336606e6e666606666000000000000000000000000000000000000000000000000007760777006770033333333303330333333333333333333
33333333333333336606e6e666606666777777707777777777770770770777777777777077777777707707770770770733333333333333333333333333333333
333333f3333333f36606e6e6660666667777777777777777777770707077777777777777777777777075777077775707333333f33633363399933333333333f3
3f3333333f3333336606eee66066666677777777777777777777770007777777777777777777777770707777777707073f333333060306039a9999993f333333
3333f3333333f333660666660666666677777777777777777777777777777777777777777777777770777777777777073333f33330333033939aa9a93333f333
333333333333333366066660666666667777777777777777777777777777777777777777777777777077777777777707333333333333333399933a3a33333333
333333f3333333f366666666666666667777777777777777777777777777777777777777777777777077777777777707333333f336333633aaa33333333333f3
333f3333333f333366666666666666667777777777777777777777777777777777777777777777777000000000000007333f33330603060333333333333f3333
33333333333333336666666666666666777777777777777777777777777777777777777777777777777777777777777733333333303330333333333333333333
33333333333333330000000000000000767677676777676776767767677767673333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3000000000000000065555555555555576555555555555557333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
3f3333333f3333330000077777000000755555555555555675555555555555563f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333333
3333f3333333f33300007700077000006ccccccccc7cccc765555555557555573333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333
333333333333333300077000007700007ccc7cccccc7ccc675557555555755563333333333333333333333333333333333333333333333333333333333333333
333333f3333333f300070000000700007cccc7cccccc0cc77555575555550557333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
333f3333333f333300070000000700006cccccccccccc0c66555555555555056333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333
333333333333333300070000000700007cccccc00000000775555550000000073333333333333333333333333333333333333333333333333333333333333333
333333333333333300070000000700007cccccccccccc0c775555555555550573333333333333333333333333333333333333333333333333333333333333333
333333f3333333f300070000000700006ccccccccccc0cc66555555555550556333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
3f3333333f33333300077000007700007ccccccccc7cccc775555555557555573f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333333
3333f3333333f33300007700077000006ccc7cccccc7ccc665557555555755563333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333
333333333333333300000777770000007cccc7ccccccccc775555755555555573333333333333333333333333333333333333333333333333333333333333333
333333f3333333f300000007000000007cccccccccccccc77cccccccccccccc7333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
333f3333333f333300000007770000006cccccccccccccc66cccccccccccccc6333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333
33333333333333330000000000000000776776776767767777677677676776773333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33333333333443333333333333333333
333333f3333333f3333333f3333333f3f66666666666666ff66666666666666ff66666666666666ff66666666666666f333333f3333443f3333333f3333333f3
3f3333333f3333333f3333333f333333f66666666666666ff66666666666666ff66666666666666ff66666666666666f3f333333399999933f3333333f333333
3333f3333333f3333333f3333333f333f06666666606666ff06666666606666ff06666666606666ff06666666606666f3333f333939999393333f3333333f333
33333333333333333333333333333333f06666666660666ff06666666660666ff06666666660666ff06666666660666f33333333439999343333333333333333
333333f3333333f3333333f3333333f3f06eee6aaa66066ff06eee66a666066ff066e66aaa66066ff066e666a666066f333333f333aaaaf3333333f3333333f3
333f3333333f3333333f3333333f3333f06e6e6a6a66606ff06e6e6aa666606ff06ee66a6a66606ff06ee66aa666606f333f333333af3a33333f3333333f3333
33333333333333333333333333333333f06e6e6a6a66660ff06e6e66a666660ff066e66a6a66660ff066e666a666660f3333333333a33a333333333333333333
33333333333333333333333333333333f06e6e6a6a66660ff06e6e66a666660ff066e66a6a66660ff066e666a666660f33333333333333333333333333333333
333333f3333333f3333333f3333333f3f06e6e6a6a66606ff06e6e66a666606ff066e66a6a66606ff066e666a666606f333333f3333333f3333333f3333333f3
3f3333333f3333333f3333333f333333f06eee6aaa66066ff06eee6aaa66066ff06eee6aaa66066ff06eee6aaa66066f3f3333333f3333333f3333333f333333
3333f3333333f3333333f3333333f333f06666666660666ff06666666660666ff06666666660666ff06666666660666f3333f3333333f3333333f3333333f333
33333333333333333333333333333333f06666666606666ff06666666606666ff06666666606666ff06666666606666f33333333333333333333333333333333
333333f3333333f3333333f3333333f3f66666666666666ff66666666666666ff66666666666666ff66666666666666f333333f3333333f3333333f3333333f3
333f3333333f3333333f3333333f3333f66666666666666ff66666666666666ff66666666666666ff66666666666666f333f3333333f3333333f3333333f3333
33333333333333333333333333333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
3f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333333
3333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
3f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333333
3333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
3f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333333
3333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
3f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333333
3333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
3f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333333
3333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
3f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333333
3333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3
333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333333f3333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333

__gff__
0000000000000101000000000000000000000000000001010000000000002180020000000000000000000000000048100301000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101e0c1e0e1e0e1e0e10101010101010101e0e1e0e1e0e1e0e1e0e10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
01010101f0f1f0f1f0f1f0f10101010101010101f0f1f0f1f0f1f0f1f0f10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
__sfx__
000400000d03000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000000029050000000000036050360503605036040360303602036020360203500035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000013050130501f0502d0502d000270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000070500d05014000170001a000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
