-- title:  game title
-- author: game developer
-- desc:   short description
-- script: lua

T = 8
W = 240
H = 136

W3D=1.2*2
H3D=0.65*2

sf = string.format

KEY_W = 23
KEY_A = 01
KEY_S = 19
KEY_D = 4
KEY_Q = 17
KEY_R = 18
KEY_E = 5
UP=0
DOWN=1
LEFT=2
RIGHT=3
BTN_Z=4
BTN_X=5

cos = math.cos
sin = math.sin
abs = math.abs
PI = math.pi

function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepcopy(orig_key)] = deepcopy(orig_value)
    end
    setmetatable(copy, deepcopy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

-- math

function angle_dist( a,b )
  return math.atan2(sin(a-b),cos(a-b))
end

function det( a,b,c,d )
  return a*d - b*c
end

function line_crossv( s1,e1,s2,e2 )
  local x,y = line_cross(s1.x,s1.y,e1.x,e1.y,s2.x,s2.y,e2.x,e2.y)
  if x == nil or y == nil then
    return nil
  else
    return v2(x,y)
  end
end

function line_cross( x1,y1,x2,y2,x3,y3,x4,y4 )
  local pxup,pxdn,pyup,pydn
  pxup = det(det(x1,y1,x2,y2), x1-x2, det(x3,y3,x4,y4), x3-x4)
  pxdn = det(x1-x2, y1-y2, x3-x4, y3-y4)

  pyup = det(det(x1,y1,x2,y2), y1-y2, det(x3,y3,x4,y4), y3-y4)
  pydn = det(x1-x2, y1-y2, x3-x4, y3-y4)

  if abs(pxdn) <= 0.0001 or abs(pydn) <= 0.0001 then
    return nil,nil
  else
    return pxup/pxdn, pyup/pydn
  end
end

-- 2d

function v2( x,y )
  return{x=x,y=y}
end

function v2add( v1,v2 )
  return {x=v1.x+v2.x,y=v1.y+v2.y}
end

function v2mul( v,n )
  return {x=v.x*n,y=v.y*n}
end

function v2dist( v1,v2 )
  local p1,p2 = sq(v1.x-v2.x),sq(v1.y-v2.y)
  local res = math.sqrt(p1+p2)
  return res
end

function v2angle( v1,v2 )
  return -math.atan2(v2.y-v1.y, v2.x-v1.x)
end

function linev( v1,v2,c )
  line(v1.x,v1.y,v2.x,v2.y,c)
end

function circv( v,r,c )
  circ(v.x,v.y,r,c)
end

-- 3d

cam={
  x=0,
  y=0,
  z=0,
  rx=0,
  ry=0,
  rz=0
}

function cam_proj( x,y,z )
  local x1,y1,z1

  local dx,dy,dz = x - cam.x, y - cam.y, z - cam.z
  local cx,cy,cz = cos(cam.rx), cos(cam.ry), cos(cam.rz)
  local sx,sy,sz = sin(cam.rx), sin(cam.ry), sin(cam.rz)

  x1 = cy*(sz*dy + cz*dx) - sy*dz
  y1 = sx*(cy*dz + sy*(sz*dy + cz*dx)) + cx*(cz*dy - sz*dx)
  z1 = cx*(cy*dz + sy*(sz*dy + cz*dx)) - sx*(cz*dy - sz*dx)

  return x1,y1,z1
end

function cam_projv( v )
  local x1,y1,z1 = cam_proj(v.x,v.y,v.z)
  return v3(x1,y1,z1)
end

function point_3d_proj( x1,y1,z1 )
  if z1 <= 0.00001 then return nil,nil end

  local x2d,y2d = x1/z1, y1/z1
  local xnorm, ynorm = (x2d + W3D/2) / W3D, (y2d + H3D/2) / H3D
  local xproj, yproj = xnorm * W, (-ynorm + 1) * H
  return xproj, yproj
end

function point_3d( x,y,z )
  local x1,y1,z1 = cam_proj(x,y,z)
  return point_3d_proj(x1,y1,z1)
end

function point_3dv( v )
  local x,y = point_3d(v.x,v.y,v.z)
  if x == nil or y == nil then return nil end
  return v2(x,y)
end

function circ_3dv( v,r )
  local cpos = point_3dv(v)
  if cpos == nil then return nil,nil end
  local cproj = cam_projv(v)
  local tg_pos = v3add(cproj,v3(r,0,0))
  local tg_x,tg_y = point_3d_proj(tg_pos.x,tg_pos.y,tg_pos.z)
  if tg_x == nil or tg_y == nil then return nil,nil end
  return cpos,v2dist(cpos,v2(tg_x,tg_y))
end

calls = 0
function line_3d( x1,y1,z1,x2,y2,z2,c )
  local xp1,yp1,zp1 = cam_proj(x1,y1,z1)
  local xp2,yp2,zp2 = cam_proj(x2,y2,z2)

  if zp1 <= 0.0001 and zp2 <= 0.0001 then return end
  -- adjust line length
  if zp1 <= 0.0001 then
    local frac = abs(zp2)/abs(zp1-zp2)
    zp1 = 0.1
    xp1 = frac * (xp1 - xp2) + xp2
    yp1 = frac * (yp1 - yp2) + yp2
  elseif zp2 <= 0.0001 then
    local frac = abs(zp1)/abs(zp1-zp2)
    zp2 = 0.1
    xp2 = frac * (xp2 - xp1) + xp1
    yp2 = frac * (yp2 - yp1) + yp1
  end

  local c1,c2,c3,c4 = 0,8,15,14

  local avg_z = math.min(zp1,zp2)
  local color = c1
  if avg_z >= 10 and avg_z < 20 then
    color = c2
  elseif avg_z >= 20 and avg_z < 40 then
    color = c3
  elseif avg_z >= 40 and avg_z < 100 then
    color = c4
  elseif avg_z >= 100 then
    return
  end

  local xn1,yn1 = point_3d_proj(xp1,yp1,zp1)
  local xn2,yn2 = point_3d_proj(xp2,yp2,zp2)
  -- trace(sf("%.2f %.2f %.2f %.2f", xn1, xn2, yn1, yn2))
  if xn1 == nil or xn2 == nil then return end
  line(xn1,yn1,xn2,yn2,color)
  calls = calls + 1
end

function v3( x,y,z )
  return {x=x,y=y,z=z}
end

function v223( v2,z )
  return {x=v2.x,y=v2.y,z=z}
end

function sq( v )
  return v*v
end

function v3add( v1,v2 )
  return {x=v1.x+v2.x,y=v1.y+v2.y,z=v1.z+v2.z}
end

function v3div( v3,n )
  return {v3.x/n, v3.y/n, v3.z/n}
end

function v3divxy( v3,n )
  return {v3.x/n, v3.y/n, v3.z}
end

function v3dist( v1,v2 )
  return math.sqrt((v1.x-v2.x)^2+(v1.y-v2.y)^2+(v1.z-v2.z)^2)
end

function line_3dv( v1,v2,c )
  line_3d(v1.x,v1.y,v1.z,v2.x,v2.y,v2.z,c)
end

function tri_3dv( v1,v2,v3,c )
  local p1,p2,p3 = point_3dv(v1), point_3dv(v2), point_3dv(v3)
  if p1 == nil or p2 == nil or p3 == nil then return end
  tri(p1.x,p1.y,p2.x,p2.y,p3.x,p3.y,c)
end

function line_3dvv( vecs,c )
  for i=1,#vecs-1 do
    line_3dv(vecs[i], vecs[i+1], c)
  end
end

function fig_3d( fig,c )
  if c == nil then c = 1 end
  for i,v in ipairs(fig.edges) do
    for j=1,#v-1 do
      line_3dv(fig.vert[v[j]], fig.vert[v[j+1]], 1)
    end
  end
end

function fig3d_add( f1,f2 )
  if f1.vert == nil then
    f1.vert = deepcopy(f2.vert)
    f1.edges = deepcopy(f2.edges)
  else
    local vertsize = #f1.vert
    for i,v in ipairs(f2.vert) do
      table.insert(f1.vert,v)
    end

    for i,v in ipairs(f2.edges) do
      local ne = {}
      for j,e in ipairs(v) do
        table.insert(ne, e + vertsize)
      end
      table.insert(f1.edges, ne)
    end
  end
end

function fig3d_addv( f,v1,v2 )
  return fig3d_add(f, {vert={v1,v2},edges={{1,2}}})
end

function rot_2d( x0, y0, cx, cy, angle )
  local x1,y1,da,dist
  dist = v2dist(v2(cx,cy), v2(x0,y0))
  da = math.atan(y0-cy, x0-cx)
  x1 = dist * cos(angle + da) + cx
  y1 = dist * sin(angle + da) + cy
  return x1,y1
end

function move_fig( fig,dv )
  for i,v in ipairs(fig.vert) do
    local res = v3add(v,dv)
    v.x,v.y,v.z = res.x,res.y,res.z
  end
end

function rot_3d( fig, cv, rot )
  for i,v in ipairs(fig.vert) do
    v.x, v.y = rot_2d(v.x, v.y, cv.x, cv.y, rot.i)
    v.x, v.z = rot_2d(v.x, v.z, cv.x, cv.z, rot.j)
    v.y, v.z = rot_2d(v.y, v.z, cv.y, cv.z, rot.k)
  end
end

-- rails

function link_rails( p,n,f,b,reverse )
  if f then
    if p.next == nil then
      p.next = {{val=n, rev=reverse}}
      p.next_active = 1
    else
      table.insert(p.next, {val=n, rev=reverse})
    end
  end
  if b then
    if n.prev == nil then
      n.prev = {{val=p, rev=reverse}}
      n.prev_active = 1
    else
      table.insert(n.prev, {val=p, rev=reverse})
    end
  end
end

function add_rail( rails, parent, r, reverse )
  if parent == nil then
    r.angle = r.da
  elseif reverse then
    r.angle = parent.angle + r.da
    r.pos = v2add(parent.pos, v2mul(v2(r.len * cos(r.angle), -1 * r.len * sin(r.angle)),-1))
  else
    r.angle = parent.angle + r.da
    r.pos = v2add(parent.pos, v2(parent.len * cos(parent.angle), -1 * parent.len * sin(parent.angle)))
  end
  table.insert(rails, r)
end

function connect_rails( r1,r2,rail,rev1,rev2 )
  local pos2,pos1 = r1.pos,r2.pos
  if rev1 then
    local _,_,_,_,end_pos = calc_rails(r1)
    pos1 = end_pos
  end
  if rev2 then
    local _,_,_,_,end_pos = calc_rails(r2)
    pos2 = end_pos
  end
  rail.pos = pos1
  rail.angle = v2angle(pos1,pos2)
  rail.len = v2dist(pos1,pos2)
end

function loop_rails( r1,r2,reverse )
  if reverse then
    local _,_,_,_,end_pos = calc_rails(r2)
    r1.angle = v2angle(r1.pos, end_pos)
    r1.len = v2dist(r1.pos, end_pos)
  else
    r1.angle = v2angle(r1.pos, r2.pos)
    r1.len = v2dist(r2.pos, r1.pos)
  end
end

function make_turn( rails,p,angle,reverse )
  local ca,da,len = 0,PI/12,5.0
  if angle < 0 then da = -da end
  local cr = p
  while abs(angle_dist(ca,angle)) >= PI/12 do
    ca = ca + da
    local r = deepcopy(rail)
    r.len = len
    r.da = da
    add_rail(rails, cr, r, reverse)
    if reverse then
      link_rails(r, cr, true, true, false)
    else
      link_rails(cr, r, true, true, false)
    end
    cr = r
  end
  return cr
end

function make_straight( rails,p,len,reverse )
  local r = deepcopy(rail)
  r.len = len
  r.da = 0
  add_rail(rails,p,r,reverse)
  if reverse then
    link_rails(r,p,true,true,false)
  else
    link_rails(p,r,true,true,false)
  end
  return r
end

function calc_rails( r,just_end_pos )
  local end_pos = v2add(r.pos, v2(r.len * cos(r.angle), -1 * r.len * sin(r.angle)))
  if just_end_pos then return nil,nil,nil,nil,end_pos end

  local rw = 2  -- rail width
  local lnorm,rnorm = r.angle + PI / 2, r.angle - PI / 2
  local lstart,lend,rstart,rend,dl,dr
  dl = v2(rw * cos(lnorm), -rw * sin(lnorm))
  dr = v2(rw * cos(rnorm), -rw * sin(rnorm))
  lstart = v2add(r.pos, dl)
  lend = v2add(end_pos, dl)
  rstart = v2add(r.pos, dr)
  rend = v2add(end_pos, dr)
  return lstart,lend,rstart,rend,end_pos
end

function add_scale( m,p1,p2 )
  local dx,dy = p2.x-p1.x, p2.y-p1.y
  for i=1,10 do
    fig3d_addv(m, v3(p1.x+dx*(i-1)/10, p1.y+dy*(i-1)/10,p1.z),v3(p1.x+dx*i/10, p1.y+dy*i/10,p1.z))
  end
end

function make_rails_3d( ls,le,rs,re,a )
  local r_w = 1
  local model = deepcopy(obj_3d)
  local l1,l2,l3,l4,l5,l6,r1,r2,r3,r4,r5,r6
  l1 = v3(ls.x,ls.y,0)
  l2 = v3(le.x,le.y,0)
  fig3d_addv(model, l1,l2)
  l3 = v3add(l1,v3(0,0,0.5))
  l4 = v3add(l2,v3(0,0,0.5))
  fig3d_addv(model, l3,l4)
  -- l5 = v3add(l3,v3(r_w*cos(a+PI/2),r_w*sin(a+PI/2),0))
  -- l6 = v3add(l4,v3(r_w*cos(a+PI/2),r_w*sin(a+PI/2),0))
  -- fig3d_addv(model, l5,l6)
  r1 = v3(rs.x,rs.y,0)
  r2 = v3(re.x,re.y,0)
  fig3d_addv(model, r1,r2)
  r3 = v3add(r1,v3(0,0,0.5))
  r4 = v3add(r2,v3(0,0,0.5))
  fig3d_addv(model, r3,r4)
  -- r5 = v3add(r3,v3(r_w*cos(a-PI/2),r_w*sin(a-PI/2),0))
  -- r6 = v3add(r4,v3(r_w*cos(a-PI/2),r_w*sin(a-PI/2),0))
  -- fig3d_addv(model, r5,r6)
  return model
end

tutor_rail = nil
function init_rails( rails )
  local R_LEN=50

  local cr = deepcopy(rail)
  cr.len = 5.0
  local start = cr
  add_rail(rails, nil, cr)

  local r1 = make_turn(rails,start,PI,false)

  local r2 = make_straight(rails,r1,R_LEN)
  tutor_rail = r2
  local r3 = make_straight(rails,r2,R_LEN)

  local r4 = make_turn(rails,r3,PI,false)

  local r5 = make_straight(rails,r4,R_LEN)
  local r6 = make_straight(rails,r5,R_LEN)

  link_rails(r6,start,true,true,false)
  loop_rails(r6,start)

  local r7 = make_turn(rails,r5,-PI/2)

  local r8 = make_straight(rails,r7,R_LEN*2)
  local r9 = make_straight(rails,r8,R_LEN)

  local r10 = make_turn(rails,r9,-PI/2)

  local r11 = make_straight(rails,r10,R_LEN)
  
  local r12 = make_turn(rails,r11,-PI/2)

  local r13 = make_turn(rails,r9,PI/2,true)
  r9.prev_active=2

  local r14 = make_straight(rails,r13,R_LEN,true)

  local r15 = make_turn(rails,r14,PI/2,true)

  local r16 = make_straight(rails,r12,R_LEN)
  loop_rails(r16,r15)
  link_rails(r16,r15,true,true,false)
  r16.prev_active=2

  local r17 = make_turn(rails,r16,PI/2)
  local r18 = make_turn(rails,r16,-PI/2,true)

  local r19 = make_straight(rails,r18,R_LEN,true)
  local r20 = make_straight(rails,r17,R_LEN)

  local r21 = make_turn(rails,r19,-PI/2,true)
  local r22 = make_turn(rails,r20,PI/2)

  loop_rails(r22,r21)
  link_rails(r22,r21,true,true,false)

  local r23 = make_straight(rails,r11,R_LEN,false)
  loop_rails(r23,r19,true)
  link_rails(r19,r23,true,false,true)
  link_rails(r23,r19,true,false,true)
  r11.next_active=2

  local r24 = make_straight(rails,r20,R_LEN,true)
  link_rails(r24,r14,false,true,true)
  link_rails(r14,r24,false,true,true)
  connect_rails(r20,r14,r24,false,false)
  r20.prev_active=2

  local r25 = make_turn(rails,r3,PI/2,true)

  local r26 = make_straight(rails,r25,10,true)
  local finish = make_straight(rails,r26,5,true)
  finish.finish = true

  return r5,finish
end

function init_rail_gfx( r )
  local lstart,lend,rstart,rend,end_pos = calc_rails(r)
  if r.prev ~= nil then
    local p = r.prev[1].val
    local plstart,plend,prstart,prend,pend_pos = calc_rails(p)
    local cl,cr
    if r.prev[1].rev then
      plstart,plend,prstart,prend = prstart,prend,plstart,plend
    end
    cl = line_crossv(lstart,lend,plstart,plend)
    cr = line_crossv(rstart,rend,prstart,prend)
    if cl ~= nil then lstart = cl end
    if cr ~= nil then rstart = cr end
  end
  if r.next ~= nil then
    local n = r.next[1].val
    local nlstart,nlend,nrstart,nrend,nend_pos = calc_rails(n)
    local cl,cr
    if r.next[1].rev then
      nlstart,nlend,nrstart,nrend = nrstart,nrend,nlstart,nlend
    end
    cl = line_crossv(lstart,lend,nlstart,nlend)
    cr = line_crossv(rstart,rend,nrstart,nrend)
    if cl ~= nil then lend = cl end
    if cr ~= nil then rend = cr end
  end

  -- draw switch
  if r.next ~= nil and #r.next > 1 then
    table.insert(r.circles, end_pos)
    local btn = deepcopy(circ_button)
    btn.on_press = function ()
      r.next_active = r.next_active + 1
      if r.next_active > #r.next then r.next_active = 1 end
    end
    r.btn_next = btn
    table.insert(BTNS, btn)
  end
  if r.prev ~= nil and #r.prev > 1 then
    table.insert(r.circles, r.pos)
    local btn = deepcopy(circ_button)
    btn.on_press = function ()
      r.prev_active = r.prev_active + 1
      if r.prev_active > #r.prev then r.prev_active = 1 end
    end
    r.btn_prev = btn
    table.insert(BTNS, btn)
  end

  -- minimap-optimized line drawing
  local segs = math.floor(v2dist(r.pos,end_pos) / 10) + 1
  for i=1,segs do
    local blx,bly,elx,ely,brx,bry,erx,ery
    -- blx = (lend.x - lstart.x) * (i-1)/segs + lstart.x
    -- bly = (lend.y - lstart.y) * (i-1)/segs + lstart.y
    -- elx = (lend.x - lstart.x) * i/segs + lstart.x
    -- ely = (lend.y - lstart.y) * i/segs + lstart.y
    -- brx = (rend.x - rstart.x) * (i-1)/segs + rstart.x
    -- bry = (rend.y - rstart.y) * (i-1)/segs + rstart.y
    -- erx = (rend.x - rstart.x) * i/segs + rstart.x
    -- ery = (rend.y - rstart.y) * i/segs + rstart.y
    -- table.insert(r.lines, {v2(blx,bly),v2(elx,ely)})
    -- table.insert(r.lines, {v2(brx,bry),v2(erx,ery)})
    blx = (end_pos.x - r.pos.x) * (i-1)/segs + r.pos.x
    bly = (end_pos.y - r.pos.y) * (i-1)/segs + r.pos.y
    elx = (end_pos.x - r.pos.x) * i/segs + r.pos.x
    ely = (end_pos.y - r.pos.y) * i/segs + r.pos.y
    table.insert(r.lines, {v2(blx,bly),v2(elx,ely)})
  end

  local rail_3d = make_rails_3d(lstart, lend, rstart, rend, r.angle)
  r.model = rail_3d
end

function draw_rail( r,delta,c )
  local thr = 75
  for i,v in ipairs(r.lines) do
    local v1,v2 = v2add(v[1],delta),v2add(v[2],delta)
    if v2dist(v1,MINIMAP_POS) < thr or v2dist(v2,MINIMAP_POS) < thr then
      linev(v2mul(v1,MINIMAP_SCALE),v2mul(v2,MINIMAP_SCALE), c)
    end
  end
  for i,v in ipairs(r.circles) do
    local v1 = v2add(v,delta)
    if v2dist(v1,MINIMAP_POS) < thr then
      circv(v2mul(v1,MINIMAP_SCALE), 2, 3)
    end
  end
end

function draw_arrow( r,nxt,c,is_prev )
  local arr_len = 10
  local n = nxt.val
  local left,right,end_pos,center
  if is_prev then
    left,_,right,_,end_pos = calc_rails(r)
    local dc = v2(arr_len * cos(n.angle + PI), -arr_len*sin(n.angle + PI))
    if nxt.rev then dc = v2mul(dc,-1) end
    center = v2add(r.pos, dc)
  else
    _,left,_,right,end_pos = calc_rails(r)
    local dc = v2(arr_len * cos(n.angle), -arr_len*sin(n.angle))
    if nxt.rev then dc = v2mul(dc,-1) end
    center = v2add(end_pos, dc)
  end
  tri_3dv(v223(left,0),v223(right,0),v223(center,0),c)
end

function update_switch_buttons( t,r )
  if r.btn_next ~= nil then
    local _,_,_,_,end_pos = calc_rails(r)
    local bpos,rad = circ_3dv(v223(end_pos,0),4)
    if bpos ~= nil then
      r.btn_next.active = t.rail == r and not t.rev
      r.btn_next.x, r.btn_next.y, r.btn_next.r = bpos.x,bpos.y,rad
    else
      r.btn_next.active = false
    end
  end
  if r.btn_prev ~= nil then
    local bpos,rad = circ_3dv(v223(r.pos,0),4)
    if bpos ~= nil then
      r.btn_prev.active = t.rail == r and t.rev
      r.btn_prev.x, r.btn_prev.y, r.btn_prev.r = bpos.x,bpos.y,rad
    else
      r.btn_prev.active = false
    end
  end
end

function draw_switch_3d( r,t )
  if r.next ~= nil and #r.next > 1 and t.rail == r and not t.rev then
    local in_idx = 1
    if r.next_active == 1 then in_idx = 2 end
    local active = r.next[r.next_active]
    local inactive = r.next[in_idx]
    draw_arrow(r,inactive,3,false)
    draw_arrow(r,active,6,false)
  end
  if r.prev ~= nil and #r.prev > 1 and t.rail == r and t.rev then
    local in_idx = 1
    if r.prev_active == 1 then in_idx = 2 end
    local active = r.prev[r.prev_active]
    local inactive = r.prev[in_idx]
    draw_arrow(r,inactive,3,true)
    draw_arrow(r,active,6,true)
  end
end

function draw_rail_3d( r )
  fig_3d(r.model)
end

function move_train( t )
  local sp,slow,sslow = 0.4,0.2,0.1
  if t.rail.finish then
    game_win()
  end

  -- speed
  if intro then
    t.speed = 0.01
  elseif t.rail == tutor_rail then
    t.speed = 0.1
  elseif tutor_rail ~= nil then
    t.speed = 0.7
  else
    if (t.rev and t.rail.prev ~= nil and #t.rail.prev > 1) or (not t.rev and t.rail.next ~= nil and #t.rail.next > 1) then
      local r = t.rail
      local tpos = v2add(r.pos, v2(t.progress * cos(r.angle), -t.progress * sin(r.angle)))
      local spos = r.pos
      if not t.rev then
        _,_,_,_,spos = calc_rails(r,true)
      end
      if v2dist(spos,tpos) < 5 then
        t.speed = sslow
      elseif v2dist(spos,tpos) < 15 then
        t.speed = slow
      else
        t.speed = sp
      end
    else
      t.speed = sp
    end
  end

  local old_rail = t.rail
  if t.rev then
    t.progress = t.progress - t.speed
    if t.progress <= 0 then
      local pr = t.rail.prev[t.rail.prev_active]
      t.rail = pr.val
      t.progress = pr.val.len
      t.rev = not pr.rev
      if t.rev then t.progress = t.rail.len else t.progress = 0 end
    end
  else
    t.progress = t.progress + t.speed
    if t.progress >= t.rail.len then
      local nr = t.rail.next[t.rail.next_active]
      t.rail = nr.val
      t.rev = nr.rev
      if t.rev then t.progress = t.rail.len else t.progress = 0 end
    end
  end
  if old_rail ~= t.rail and old_rail == tutor_rail then
    tutor_rail = nil
  end
end

function draw_train( t )
  local r = t.rail
  local cpos = v2add(r.pos, v2(t.progress * cos(r.angle), -t.progress * sin(r.angle)))
  local delta = v2add(MINIMAP_POS, v2mul(cpos,-1))
  circv(v2mul(MINIMAP_POS,MINIMAP_SCALE),3,4)
  return delta
end

da = 0
dx = 0
dy = 0
function draw_train_3d( t )
  local r = t.rail
  local cpos = v2add(r.pos, v2(t.progress * cos(r.angle), -t.progress * sin(r.angle)))
  local target_x = cpos.x
  local target_y = cpos.y

  local target_rz
  if r == tutor_rail then
    target_rz = -v2angle(cpos,center) + PI / 2
  else
    target_rz = -r.angle + PI / 2
  end
  if t.rev then target_rz = target_rz - PI end
  da = angle_dist(target_rz, cam.rz)
  dx = (target_x - cam.x)
  dy = (target_y - cam.y)
  -- cam.rz = target_rz
  local rate = 30
  if intro then rate = 50
  elseif tutor_rail ~= nil then rate = 15 end 
  if (abs(angle_dist(target_rz, cam.rz)) >= 0.0001) then
    cam.rz = cam.rz + da / rate
  end
  if (math.abs(cam.x - target_x) >= 0.0001) then
    cam.x = cam.x + dx / rate
  end
  if (math.abs(cam.y - target_y) >= 0.0001) then
    cam.y = cam.y + dy / rate
  end
end

-- buttons

function draw_buttons( btns )
  for i,v in ipairs(btns) do
    if v.active then
      circb(v.x,v.y,v.r,3)
    end
  end
end

function update_buttons( btns )
  local mx,my,md = mouse()
  for i,v in ipairs(btns) do
    if v.active then
      if md and not v.press then
        if v2dist(v2(mx,my),v) < v.r then
          v.on_press()
        end
      end
      v.press = md
    end
  end
end

-- objects

obj_3d = {
  vert={},
  edges={}
}

sq_3d = {
  vert = {
    v3(1,1,0),
    v3(1,2,0),
    v3(2,1,0),
    v3(2,2,0),
  },
  edges = {
    {1,2},
    {1,3},
    {2,4},
    {3,4},
  }
}

octa_3d = {
  vert = {
    v3(1*3,1*3,0*3),
    v3(1*3,2*3,0*3),
    v3(2*3,1*3,0*3),
    v3(2*3,2*3,0*3),
    v3(1*3,0*3,1*3),
    v3(2*3,0*3,1*3),
    v3(0*3,1*3,1*3),
    v3(0*3,2*3,1*3),
    v3(1*3,3*3,1*3),
    v3(2*3,3*3,1*3),
    v3(3*3,1*3,1*3),
    v3(3*3,2*3,1*3),
    v3(1*3,0*3,2*3),
    v3(2*3,0*3,2*3),
    v3(0*3,1*3,2*3),
    v3(0*3,2*3,2*3),
    v3(1*3,3*3,2*3),
    v3(2*3,3*3,2*3),
    v3(3*3,1*3,2*3),
    v3(3*3,2*3,2*3),
    v3(1*3,1*3,3*3),
    v3(1*3,2*3,3*3),
    v3(2*3,1*3,3*3),
    v3(2*3,2*3,3*3)
  },
  edges = {
    {1,2,4,3,1},
    {5,6,11,12,10,9,8,7,5},
    {13,14,19,20,18,17,16,15,13},
    {21,22,24,23,21},
    {1,5,13,21},
    {1,7,15,21},
    {2,8,16,22},
    {2,9,17,22},
    {3,6,14,23},
    {3,11,19,23},
    {4,10,18,24},
    {4,12,20,24}
  }
}

center = {
  x = 1.5 * 3,
  y = 1.5 * 3,
  z = 1.5 * 3
}

rot_angle = {
  i = 0.01,
  j = -0.01,
  k = 0.01
}

cam.rx = 1.8
cam.rz = PI / 2

rail = {
  da = 30.0 * PI / 180,
  len = 40.0,
  pos = v2(50,100),
  next = nil,
  prev = nil,
  model={},
  lines={},
  circles={}
}

circ_button = {
  x=0,
  y=0,
  r=0,
  press=false,
  on_press=nil,
  active=false
}

RAILS = {}

BTNS = {}

OBJS_3D = {
  octa_3d
}

MINIMAP_POS=v2(75,75)
MINIMAP_SCALE=0.3

train = {
  rail = nil,
  speed = 0.4,
  progress = 0,
  rev = false
}

-- init

start,finish = init_rails(RAILS)
train.rail = start
-- train.rev=true
move_fig(octa_3d, v223(finish.pos,1.5))
center = v3add(center, v223(finish.pos,1.5))

cam.x = start.pos.x
cam.y = start.pos.y
cam.z = 20
cam.rz = (-start.angle + PI / 2)

win = false
function game_win()
  win = true
end

for i,v in ipairs(RAILS) do
  init_rail_gfx(v)
end

intro = true

dzcam = 0
target_camz = 5
function TIC()
  calls = 0
  cls(11)

  rect(0,46,W,H-46,13)
  rot_3d(octa_3d, center, rot_angle)

  if win then
    local tw = print("WIN",W,H,1,true,4)
    print ("WIN", (W - tw) / 2, H / 2,8,true,4)
  end

  local delta
  if not win and not intro and tutor_rail == nil then
    delta = draw_train(train)
  end

  draw_train_3d(train)

  for i,v in ipairs(RAILS) do
    draw_rail_3d(v)
    if not win and not intro then
      if tutor_rail == nil then
        draw_switch_3d(v,train)
        draw_rail(v, delta, 15)
        update_switch_buttons(train,v)
      end
    end
  end

  for i,v in ipairs(OBJS_3D) do
    fig_3d(v)
  end

  if not win and not intro and tutor_rail == nil then
    draw_buttons(BTNS)
    update_buttons(BTNS)
  end

  if intro then
    local tw = print("Click to play",W,H,1,true,2)
    print ("Click to play", (W - tw) / 2, H / 2,8,true,2)

    dzcam = target_camz - cam.z
    local rate = 70
    if (math.abs(cam.z - target_camz) >= 0.0001) then
      cam.z = cam.z + dzcam / rate
    end

    x,y,md = mouse()
    if md then
      intro = false
      cam.z=5
    end
  end

  if train.rail == tutor_rail then
    local text
    if train.progress < train.rail.len * 0.3 then
      text = "What are you doing with your life?"
    elseif train.progress < train.rail.len * 0.6 then
      text = "Why are you stuck in a loop?"
    else
      text = "Don't you wanna try and break it?"
    end
    local w = print(text,W,H)
    print(text,(W-w)/2,15)
  end

  -- if key(KEY_R) then
    if not win then
      move_train(train)
    end
  -- end

  -- trace(calls)

  if key(KEY_S) then cam.y = cam.y - 0.1 end
  if key(KEY_W) then cam.y = cam.y + 0.1 end
  if key(KEY_A) then cam.x = cam.x - 0.1 end
  if key(KEY_D) then cam.x = cam.x + 0.1 end
  if key(KEY_Q) then cam.z = cam.z - 0.1 end
  if key(KEY_E) then cam.z = cam.z + 0.1 end
  if btn(UP) then cam.ry = cam.ry - 0.01 end
  if btn(DOWN) then cam.ry = cam.ry + 0.01 end
  if btn(LEFT) then cam.rx = cam.rx - 0.01 end
  if btn(RIGHT) then cam.rx = cam.rx + 0.01 end
  if btn(BTN_Z) then cam.rz = cam.rz - 0.01 end
  if btn(BTN_X) then cam.rz = cam.rz + 0.01 end
  -- print(sf("%.2f: %.2f %.2f", train.rail.pos.x,train.rail.pos.y,train.rail.angle), 0, 10)
  -- print(sf("%.2f %.2f %.2f: %.2f %.2f %.2f", cam.x,cam.y,cam.z,cam.rx,cam.ry,cam.rz), 0, 18)
end
