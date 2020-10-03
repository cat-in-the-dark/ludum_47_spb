-- title:  game title
-- author: game developer
-- desc:   short description
-- script: lua

T = 8
W = 240
H = 136

W3D=1.2
H3D=0.65

sf = string.format

KEY_W = 23
KEY_A = 01
KEY_S = 19
KEY_D = 4
KEY_Q = 17
KEY_E = 5
UP=0
DOWN=1
LEFT=2
RIGHT=3
BTN_Z=4
BTN_X=5

cos = math.cos
sin = math.sin
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

-- 2d

function v2( x,y )
  return{x=x,y=y}
end

function v2dist( v1,v2 )
  local p1,p2 = sq(v1.x-v2.x),sq(v1.y-v2.y)
  local res = math.sqrt(p1+p2)
  return res
end

function v2angle( v1,v2 )
  return -math.atan2(v2.y-v1.y, v2.x-v1.x)
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

function point_3d_new( x,y,z )
  local x1,y1,z1

  local dx,dy,dz = x - cam.x, y - cam.y, z - cam.z
  local cx,cy,cz = cos(cam.rx), cos(cam.ry), cos(cam.rz)
  local sx,sy,sz = sin(cam.rx), sin(cam.ry), sin(cam.rz)

  x1 = cy*(sz*dy + cz*dx) - sy*dz
  y1 = sx*(cy*dz + sy*(sz*dy + cz*dx)) + cx*(cz*dy - sz*dx)
  z1 = cx*(cy*dz + sy*(sz*dy + cz*dx)) - sx*(cz*dy - sz*dx)

  if z1 <= 0.00001 then return nil,nil end

  local x2d,y2d = x1/z1, y1/z1
  local xnorm, ynorm = (x2d + W3D/2) / W3D, (y2d + H3D/2) / H3D
  local xproj, yproj = xnorm * W, (-ynorm + 1) * H
  return xproj, yproj
end

-- function point_3d( x,y,z )
--   local dz = z - cam.z
--   if dz <= 0.00001 then return nil,nil end
--   local x2d,y2d = (x-cam.x)/dz, (y-cam.y)/dz
--   local xnorm, ynorm = (x2d + W3D/2) / W3D, (y2d + H3D/2) / H3D
--   local xproj, yproj = xnorm * W, (-ynorm + 1) * H
--   return xproj, yproj
-- end

point_3d = point_3d_new

function line_3d( x1,y1,z1,x2,y2,z2,c )
  xn1,yn1 = point_3d(x1,y1,z1)
  xn2,yn2 = point_3d(x2,y2,z2)
  if xn1 == nil or xn2 == nil then return end
  line(xn1,yn1,xn2,yn2,c)
end

function v3( x,y,z )
  return {x=x,y=y,z=z}
end

function sq( v )
  return v*v
end

function v3add( v1,v2 )
  return {x=v1.x+v2.x,y=v1.y+v2.y,z=v1.z+v2.z}
end

function line_3dv( v1,v2,c )
  line_3d(v1.x,v1.y,v1.z,v2.x,v2.y,v2.z,c)
end

function line_3dvv( vecs,c )
  for i=1,#vecs-1 do
    line_3dv(vecs[i], vecs[i+1], c)
  end
end

function circb_3dv( v,r,c )
  local cx,cy = point_3d(v.x,v.y,v.z)
  if cx == nil then return end
  local dx=v3(r,0,0)
  local p = v3add(v,dx)
  local px,py = point_3d(p.x,p.y,p.z)
  if px == nil then return end
  local r2d = math.abs(px-cx)
  circb(cx,cy,r2d,c)
end

function rect_3d( x,y,z,w,h )
  line_3d(x, y, z, x + w, y, z)
  line_3d(x, y, z, x, y - h, z)
  line_3d(x + w, y - h, z, x, y - h, z)
  line_3d(x + w, y - h, z, x + w, y, z)
end

function fig_3d( fig )
  for i,v in ipairs(fig.edges) do
    for j=1,#v-1 do
      line_3dv(fig.vert[v[j]], fig.vert[v[j+1]], 1)
    end
  end
end

function rot_2d( x0, y0, cx, cy, angle )
  local x1,y1,da,dist
  dist = v2dist(v2(cx,cy), v2(x0,y0))
  da = math.atan(y0-cy, x0-cx)
  x1 = dist * math.cos(angle + da) + cx
  y1 = dist * math.sin(angle + da) + cy
  return x1,y1
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

function add_rail( rails, parent, r )
  local px,py
  if parent == nil then
    r.angle = r.da
  else
    r.angle = parent.angle + r.da
    px = parent.pos.x + parent.len * cos(parent.angle)
    py = parent.pos.y - parent.len * sin(parent.angle)
    r.pos = v2(px,py)
  end
  table.insert(rails, r)
end

function loop_rails( r1, r2, reverse )
  r1.angle = v2angle(r1.pos, r2.pos)
  r1.len = v2dist(r2.pos, r1.pos)
end

function draw_rail( r,c )
  local x1,y1
  if r.angle == nil then r.angle = r.da end
  x1 = r.pos.x + r.len * cos(r.angle)
  y1 = r.pos.y - r.len * sin(r.angle)
  line(r.pos.x, r.pos.y, x1, y1, c)

  -- draw switch
  if r.next ~= nil and #r.next > 1 then
    circ(x1, y1, 3, 3)
  end
  if r.prev ~= nil and #r.prev > 1 then
    circ(r.pos.x, r.pos.y, 3, 3)
  end
end

function move_train( t )
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
end

function draw_train( t )
  local r = t.rail
  local x,y = r.pos.x, r.pos.y
  x = x + t.progress * cos(r.angle)
  y = y - t.progress * sin(r.angle)
  circ(x,y,5,4)
end

-- objects

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
    v3(10,10,00),
    v3(10,20,00),
    v3(20,10,00),
    v3(20,20,00),
    v3(10,00,10),
    v3(20,00,10),
    v3(00,10,10),
    v3(00,20,10),
    v3(10,30,10),
    v3(20,30,10),
    v3(30,10,10),
    v3(30,20,10),
    v3(10,00,20),
    v3(20,00,20),
    v3(00,10,20),
    v3(00,20,20),
    v3(10,30,20),
    v3(20,30,20),
    v3(30,10,20),
    v3(30,20,20),
    v3(10,10,30),
    v3(10,20,30),
    v3(20,10,30),
    v3(20,20,30)
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
  x = 1.5,
  y = 1.5,
  z = 1.5
}

rot_angle = {
  i = 0.01,
  j = -0.01,
  k = 0.01
}

cam.x = 1.5
cam.y = 1.5
cam.z = 1.5

rail = {
  da = 30.0 * PI / 180,
  len = 40.0,
  pos = v2(50,100),
  next = nil,
  prev = nil,
}

RAILS = {}

train = {
  rail = nil,
  speed = 1.0,
  progress = 0,
  rev = false
}

-- init

r1 = deepcopy(rail)
r1.da = 0
add_rail(RAILS, nil, r1)
r2 = deepcopy(rail)
r2.da = 0
add_rail(RAILS, r1, r2)
link_rails(r1, r2, true, true, false)
r3 = deepcopy(rail)
r3.da = 60 * PI / 180
add_rail(RAILS, r2, r3)
link_rails(r2, r3, true, true, false)
-- r2.next_active=2
r4 = deepcopy(rail)
r4.da = 0
add_rail(RAILS, r2, r4)
link_rails(r2, r4, true, true, false)
r5 = deepcopy(rail)
r5.da = 60 * PI / 180
add_rail(RAILS, r3, r5)
link_rails(r3, r5, true, true, false)
r6 = deepcopy(rail)
add_rail(RAILS, r5, r6)
loop_rails(r6, r2)
link_rails(r5, r6, true, true, false)
link_rails(r6, r1, true, false, true)
link_rails(r1, r6, true, false, true)
-- r1.next_active=2
train.rail = r1

win = false
function game_win()
  win = true
end

function TIC()
  cls(14)

  draw_train(train)
  for i,v in ipairs(RAILS) do
    draw_rail(v, i)
  end

  if win then return end

  move_train(train)

  -- if key(KEY_S) then cam.y = cam.y - 0.1 end
  -- if key(KEY_W) then cam.y = cam.y + 0.1 end
  -- if key(KEY_A) then cam.x = cam.x - 0.1 end
  -- if key(KEY_D) then cam.x = cam.x + 0.1 end
  -- if key(KEY_Q) then cam.z = cam.z - 0.1 end
  -- if key(KEY_E) then cam.z = cam.z + 0.1 end
  -- if btn(UP) then cam.ry = cam.ry - 0.01 end
  -- if btn(DOWN) then cam.ry = cam.ry + 0.01 end
  -- if btn(LEFT) then cam.rx = cam.rx - 0.01 end
  -- if btn(RIGHT) then cam.rx = cam.rx + 0.01 end
  -- if btn(BTN_Z) then cam.rz = cam.rz - 0.01 end
  -- if btn(BTN_X) then cam.rz = cam.rz + 0.01 end
  -- fig_3d(octa_3d)
  -- rot_3d(octa_3d, center, rot_angle)
end
