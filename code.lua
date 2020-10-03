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
  z=0
}

function point_3d( x,y,z )
  local dz = z - cam.z
  if dz <= 0.00001 then return nil,nil end
  local x2d,y2d = (x-cam.x)/dz, (y-cam.y)/dz
  local xnorm, ynorm = (x2d + W3D/2) / W3D, (y2d + H3D/2) / H3D
  local xproj, yproj = xnorm * W, (-ynorm + 1) * H
  return xproj, yproj
end

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

function add_rail( rails, parent, r )
  local px,py
  if parent == nil then
    r.angle = r.da
  else
    r.angle = parent.angle + r.da
    px = parent.pos.x + parent.len * cos(parent.angle)
    py = parent.pos.y - parent.len * sin(parent.angle)
    r.pos = v2(px,py)
    -- TODO: implement tracks switch
    parent.next = r
    r.prev = parent
  end
  table.insert(rails, r)
end

function connect_rails( r1, r2 )
  r1.next = r2
  r2.prev = r1
  r1.angle = v2angle(r1.pos, r2.pos)
  r1.len = v2dist(r2.pos, r1.pos)
end

function draw_rail( r,c )
  local x1,y1
  if r.angle == nil then r.angle = r.da end
  x1 = r.pos.x + r.len * cos(r.angle)
  y1 = r.pos.y - r.len * sin(r.angle)
  line(r.pos.x, r.pos.y, x1, y1, c)
  return x1, y1
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
    v3(1,1,0),
    v3(1,2,0),
    v3(2,1,0),
    v3(2,2,0),
    v3(1,0,1),
    v3(2,0,1),
    v3(0,1,1),
    v3(0,2,1),
    v3(1,3,1),
    v3(2,3,1),
    v3(3,1,1),
    v3(3,2,1),
    v3(1,0,2),
    v3(2,0,2),
    v3(0,1,2),
    v3(0,2,2),
    v3(1,3,2),
    v3(2,3,2),
    v3(3,1,2),
    v3(3,2,2),
    v3(1,1,3),
    v3(1,2,3),
    v3(2,1,3),
    v3(2,2,3)
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
cam.z = -0.8

rail = {
  da = 30.0 * PI / 180,
  len = 22.0,
  pos = v2(120,130),
  next = nil,
  prev = nil,
}

RAILS = {}

start_rail = deepcopy(rail)
cr = start_rail

add_rail(RAILS, nil, start_rail)

for i=1,10 do
  local nr = deepcopy(rail)
  add_rail(RAILS, cr, nr)
  cr = nr
end

connect_rails(cr, start_rail)

function TIC()
  cls(14)
  -- if btn(UP) then cam.y = cam.y - 0.1 end
  -- if btn(DOWN) then cam.y = cam.y + 0.1 end
  -- if btn(LEFT) then cam.x = cam.x - 0.1 end
  -- if btn(RIGHT) then cam.x = cam.x + 0.1 end
  -- if btn(BTN_Z) then cam.z = cam.z - 0.05 end
  -- if btn(BTN_X) then cam.z = cam.z + 0.05 end
  -- fig_3d(octa_3d)
  -- rot_3d(octa_3d, center, rot_angle)
  for i,v in ipairs(RAILS) do
    draw_rail(v, i % 10)
  end
end
