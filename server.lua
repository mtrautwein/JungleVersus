io.stdout:setvbuf('no')
love.graphics.setDefaultFilter("nearest")

local socket = require('socket')
udp = socket.udp()
local client_IP, client_PORT = 0, 0
udp:setsockname('*',12345)
udp:settimeout(0)

local update_rate = 0.01
local update_timer = 0

local searching_client = false
local connected_to_client = false

local bump = require('bump')
local world = bump.newWorld()

-- listes fonctions
local cubes = {liste={}}
local players = {}
local arena = {}
local tirs = {}
local game = {}
local menu = {}
local chara = {}
local animation = {}
local restart = {}
local screenshake = {}
local transition = {}
local barredevie = {}
local sound = {}
---

local red = {x=120, y=300, startX=120, startY=300, w=30, h=48, vx=0, vy=0, speed=300, jump=false, shoot={liste={},bool=false,speed=600,size=15,recul=6,damage=7,gravity=4}, state='right', sante=100, round_gagne=0, choice=1} 

local blue = {x=660, y=300, startX=660, startY=300, w=30, h=48, vx=0, vy=0, speed=300, jump=false, shoot={liste={},bool=false,speed=600,size=15,recul=6,damage=7,gravity=4}, state='left', sante=100, round_gagne=0, choice=nil}

local gravity = 70
local jumpVelocity = -20.5

local gameScreen = 'menu_title'

local scale = 3

-- DIVERS --
function math.sign(n) return n>0 and 1 or n<0 and -1 or 0 end

function setColor(r,g,b) return love.graphics.setColor((r or 255)/255, (g or 255)/255, (b or 255)/255) end 

function color_list()
	setColor()
	setColor(77,132,83) -- VERT
	setColor(246,227,107) -- JAUNE
	setColor(206,181,120) -- BEIGE/MARRON
	setColor()
end	

function is_inside(item)
	if item.x+item.w >= 0 and item.x <= largeurScreen and item.y >= 0 and item.y <= hauteurScreen then 
		return true 
	else
		return false	
	end	
end	

function split(s, delimiter)
	result = {}
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end
	return result
end

function new_text_box(text,x,y,center_or_not,load_or_not)
	setColor(246,227,107) -- JAUNE

	local font = love.graphics.getFont()
	local width = font:getWidth(text) + 25

	if load_or_not ~= nil then 
		width = width + 20
		x = x -30
	end

	if center_or_not == 'center' then 
		x = (largeurScreen/2) - width/2
	end		

	love.graphics.rectangle('fill',x,y,width,30)

	setColor(77,132,83) -- VERT
	if load_or_not == true then 
		love.graphics.printf(text,x-10,y+10,width,'center')
		love.graphics.draw(anim_connection.img, anim_connection[math.floor(anim_connection.timer)],x+width-25,y+5,0,scale,scale)
	else 
		love.graphics.printf(text,x,y+10,width,'center')
	end	
end	
---

-- RESTART --
function restart.tirs()
	--Tirs removed
	for i = #red.shoot.liste, 1, -1 do
		local tir = red.shoot.liste[i]  
		world:remove(tir)  
		table.remove(red.shoot.liste,i)
	end	

	for i = #blue.shoot.liste, 1, -1 do
		local tir = blue.shoot.liste[i]  
		world:remove(tir)  
		table.remove(blue.shoot.liste,i)
	end
end	

function restart.game()
	-- delete blue
	world:remove(blue)
	blue.sante = 100
	blue.state = 'left'
	blue.x, blue.y = blue.startX, blue.startY

	blue.vx, red.vx = 0, 0

	world:remove(red)
	red.state = 'right'

	red.choice = 1
	round = 1
	red.round_gagne, blue.round_gagne = 0, 0

	screenshake.play = false

	connected_to_client = false
	searching_client = true 

	timer_connection = 10
	
	restart.tirs()
end	

function restart.round()
	if red.round_gagne < 2 and blue.round_gagne < 2 then 
		transition.to('game')

		world:remove(red)
		world:remove(blue)

		red.x, red.y, blue.x, blue.y = red.startX, red.startY, blue.startX, blue.startY

		red.vx = 0
		blue.vx = 0
	 
		world:add(red,red.x,red.y,red.w,red.h)
		world:add(blue,blue.x,blue.y,blue.w,blue.h)
	
		red.sante = 100
		blue.sante = 100

		restart.tirs()
		round = round + 1
	end	
end	
---

-- COLLIDE --
function collide(a1,a2)
		local dx = a1.x - a2.x
		local dy = a1.y - a2.y
	 	if math.abs(dx) < a1.w - 2 + a2.w - 2 then
	  		if math.abs(dy) < a1.h - 2 + a2.h - 2 then
	   			return true
	  		end
	 	end
	 	return false
end	 	

function tir_collide_with_red(tir)
	if collide(tir, red) then
		sound.play(snd_hurt)
	    red.sante = red.sante - blue.shoot.damage
	    if blue.x < red.x then 
			red.vx = red.shoot.recul
		elseif blue.x >= red.x then 
			red.vx = -blue.shoot.recul
		end
	end	
end	

function tir_collide_with_blue(tir)
	if collide(tir, blue) then
		sound.play(snd_hurt)
	    blue.sante = blue.sante - red.shoot.damage
	    if red.x < blue.x then 
			blue.vx = red.shoot.recul
		elseif red.x >= blue.x then 
			blue.vx = -red.shoot.recul
		end
	end
end		
---

-- SOUND --
function sound.new(file,pitch,volume)
	local sond 
	sond = love.audio.newSource('sonds/sond_'..file..'.wav','static')
	sond:setPitch(pitch or 1)
	sond:setVolume(volume or 1)
	return sond
end	

function sound.load()
	snd_ui = sound.new('ui',2,0.2)
	snd_jump = sound.new('jump',2,0.2)
	snd_hit = sound.new('hit',2,0.2)
	snd_hurt = sound.new('hurt',2,0.2)
	snd_explosion = sound.new('explosion',3,0.7)
	snd_bruitdejungle = love.audio.newSource('sonds/bruits-de-jungle.mp3','stream')
	snd_africanbeat = love.audio.newSource('sonds/sond_africanbeat.mp3','stream')
end	

function sound.play(sond)
	love.audio.stop(sond)
	love.audio.play(sond)
end
---

-- SCREENSHAKE --
function screenshake.load()
	screenshake.timer = 0
	screenshake.duration = 0.15
	screenshake.intensity = 2.5
	screenshake.play = false
end	

function screenshake.update(dt)
	if screenshake.timer < screenshake.duration and screenshake.play == true then 
		screenshake.timer = screenshake.timer + dt
	else 
		screenshake.timer, screenshake.play = 0, false	
	end		
end	

function screenshake.draw() 
	local dx, dy
	if screenshake.play == true then 
		dx = love.math.random(-screenshake.intensity, screenshake.intensity)
		dy = love.math.random(-screenshake.intensity, screenshake.intensity)
		love.graphics.translate(dx, dy)
	end 
end	
---

-- TRANSITION --
function transition.load()
	transition.alpha = 0
	transition.alphaMax = 1.2
	transition.vitesse = 6
	transition.state = 1
	transition.play = false
	transition.goal = nil
end	

function transition.to(goal_screen)
	transition.play = true 
	transition.goal = goal_screen
end		

function transition.update(dt)
	if transition.play == true then 
		if transition.state == 1 then 
			transition.alpha = transition.alpha + transition.vitesse*dt
			if transition.alpha > transition.alphaMax then 
				transition.state = 2
			end	
		elseif transition.state == 2 then 
				gameScreen = transition.goal
				transition.alpha = transition.alpha - transition.vitesse*dt
			if transition.alpha <= 0 then 
				transition.state = 1
				transition.play = false
			end
		end	
	end	
end	

function transition.draw()
	love.graphics.setColor(77/255,132/255,83/255,transition.alpha)
	love.graphics.rectangle('fill', 0, 0, largeurScreen, hauteurScreen)
	love.graphics.setColor(1,1,1)
end	
---

-- ARENA --	
function arena.load()
	map = require('map')
	map.couche1 = map.layers[1].data
	map.couche2 = map.layers[2].data
	map.couche3 = map.layers[3].data
	map.img_tileset = love.graphics.newImage('images/img_tileset.png')
	map.tile = {} 

	local id = 1
	for l = 1, map.height do
		for c = 1, map.width do
			map.tile[id] = love.graphics.newQuad ((c-1)*map.tilewidth, (l-1)*map.tileheight, map.tilewidth, map.tileheight, map.img_tileset:getWidth(), map.img_tileset:getHeight())
			id = id + 1
			local x = (c-1) * 30
		    local y = (l-1) * 30
		    if map.couche1[((l-1)*map.width)+c] ~= 0 then 
				cubes.add(x,y,30,30)
			end
			if map.couche3[((l-1)*map.width)+c] ~= 0 then -- Ajout des cubes pour permettre de passer à travers les murs
				cubes.add(x-30,y,30,30)
				cubes.add(x-60,y,30,30)
				cubes.add(x+largeurScreen,y,30,30)
				cubes.add(x+largeurScreen+30,y,30,30)
			end	
		end
	end		
end			

function arena.draw()
	for l = 1, map.height do
		for c = 1, map.width do
			local x = (c-1) * 30
	     	local y = (l-1) * 30
	     	local tile_couche1 = map.couche1[((l-1)*map.width)+c] 
	     	local tile_couche2 = map.couche2[((l-1)*map.width)+c] 
			
			if tile_couche1 ~= 0 then
      			love.graphics.draw(map.img_tileset,map.tile[tile_couche1],x,y,0,scale,scale)
			end	
			if tile_couche2 ~= 0 then 
      			love.graphics.draw(map.img_tileset,map.tile[tile_couche2],x,y,0,scale,scale)
			end	

		end	
	end	
end
---

-- ANIMATION --
function animation.new(pAnim_table, img_file, nombre_de_frames, vitesse, state)
	pAnim_table.img = love.graphics.newImage('animations/'..img_file..'.png')
	pAnim_table.vitesse = vitesse
	pAnim_table.timer = 1
	pAnim_table.maxTimer = nombre_de_frames
	pAnim_table.bool = state
	local width = pAnim_table.img:getWidth()/nombre_de_frames
	local height = pAnim_table.img:getHeight()
	local id = 1
   	for c = 1, nombre_de_frames+1 do
     	pAnim_table[id] = love.graphics.newQuad ((c-1)*width, 0, width, height, pAnim_table.img:getWidth(), pAnim_table.img:getHeight())
        id = id + 1
    end
end

function animation.load()
	anim_flecheJoueur = {}
	animation.new(anim_flecheJoueur,'anim_flecheJoueur', 4, 9, true)

	anim_connection = {}
	animation.new(anim_connection,'anim_connection', 2, 5, true)

	anim_explosion = {}
	animation.new(anim_explosion,'anim_explosion', 5, 10, false)

	play_explosion = false
end

function animation.play(pAnim_table, nombre_de_fois,dt)
	if pAnim_table.bool == true then -- Si l'animation doit être joué alors
		pAnim_table.timer = pAnim_table.timer + pAnim_table.vitesse*dt -- On incrémente un timer 
		if math.floor(pAnim_table.timer) > pAnim_table.maxTimer then -- Si on dépasse le nombre d'images 
			pAnim_table.timer = 1 -- On relance l'animation du début
			if nombre_de_fois ~= 'loop' then  
				pAnim_table.bool = false
			end	
		end			
		return pAnim_table.timer
	end
end	

function animation.update(dt)
	--udpate
	animation.play(anim_flecheJoueur, 'loop' ,dt)

	if play_explosion == true then 
		animation.play(anim_explosion,'non',dt)
	end	
end	

function animation.draw()
	--draw
	love.graphics.draw(anim_flecheJoueur.img, anim_flecheJoueur[math.floor(anim_flecheJoueur.timer)], red.x+red.w/2-5, red.y - 17,0,scale,scale)
	
	if anim_explosion.bool == true then 
		love.graphics.draw(anim_explosion.img, anim_explosion[math.floor(anim_explosion.timer)],10,10,0,scale,scale)
	end	
end	
---

-- TIRS --
function tirs.create(player)
	local tir = {y=player.y, vx=0, vy=0, w=player.shoot.size, h=player.shoot.size, direction=player.state,img=player.shoot.img,rotation=0,is_dead=false}

	if tir.direction == 'right' then 
		tir.x = player.x + player.w
	elseif tir.direction == 'left' then 
		tir.x = player.x - player.shoot.size
	end	

	table.insert(player.shoot.liste, tir)
	world:add(tir,tir.x,tir.y,tir.w,tir.h)
	return tir
end

function tirs.delete(tir, cols, len)
	for i = 1, len do
    	local col = cols[i]
    	if col.normal.x == -1 or col.normal.x == 1 or col.normal.y == -1 or col.normal.y == 1 then  
    		if is_inside(tir) then 
    			sound.play(snd_explosion)
    			world:remove(tir) 	
    			return true
    		end
    	end	
    end		
end	

function tirs.trajectoire(player, tir, dt)
	tir.vx = 0
	tir.vx = tir.vx + player.shoot.speed*dt
	tir.vy = tir.vy + player.shoot.gravity*dt
end	

function tirs.through_walls(tir, dt)
	-- MURS
	if tir.x > largeurScreen then 
		world:remove(tir)
		tir.x = -tir.w
		world:add(tir,tir.x,tir.y,tir.w,tir.h)
	elseif tir.x+tir.w < 0 then 
		world:remove(tir)
		tir.x = largeurScreen
		world:add(tir,tir.x,tir.y,tir.w,tir.h)
	end
end	

function tirs.update(player, dt)
	for i = #player.shoot.liste, 1, -1 do
		local tir = player.shoot.liste[i]

		tirs.trajectoire(player, tir, dt)

		if tir.direction == 'right' then 
			tir.x, tir.y, cols, len = world:move(tir, tir.x + tir.vx, tir.y + tir.vy)
		elseif tir.direction == 'left' then 
			tir.x, tir.y, cols, len = world:move(tir, tir.x - tir.vx, tir.y + tir.vy)
		end	
		
		if tirs.delete(tir, cols, len) then 
			if player == red then 
				tir_collide_with_blue(tir)
			elseif player == blue then 
				tir_collide_with_red(tir)
			end	
			screenshake.play = true
			table.remove(player.shoot.liste,i)
		end	

		tirs.through_walls(tir, dt)		
	end	
end	

function tirs.draw(player)
	for i = #player.shoot.liste, 1, -1 do
		local tir = player.shoot.liste[i]
		love.graphics.draw(tir.img,tir.x,tir.y,tir.rotation,scale,scale)
	end
end
---

-- CUBES --
function cubes.add(x,y,w,h)
  local cube = {x=x,y=y,w=w,h=h}
  cubes.liste[#cubes.liste+1] = cube
  world:add(cube, x,y,w,h)
end 
 
function cubes.draw()
  for _,cube in ipairs(cubes.liste) do
   love.graphics.setColor(1,1,1)
   love.graphics.rectangle("line", cube.x, cube.y, cube.w, cube.h)
   love.graphics.setColor(1,1,1)
  end
end
---	

-- CHARACTERS --
function chara.load_big(player)
	player.vx, player.vy = 0, 0
	player.w, player.h, player.speed = 48, 48, 225
	player.startY = hauteurScreen-60-player.h
	player.x, player.y = player.startX, player.startY
	player.shoot.speed, player.shoot.size, player.shoot.recul, player.shoot.damage, player.shoot.gravity = 500, 30, 10, 15, 10
	player.shoot.img = love.graphics.newImage('images/img_tir_big.png')
	player.shoot.timer = 10
	player.shoot.cadence = 20

	player.anim_walk_left = {}
	animation.new(player.anim_walk_left,'anim_big_walk_left',6,9, true)
	player.anim_walk_right = {}
	animation.new(player.anim_walk_right,'anim_big_walk_right',6,9, true)

	return player
end

function chara.load_middle(player)
	player.vx, player.vy = 0, 0
	player.w, player.h, player.speed = 30, 48, 300
	player.startY = hauteurScreen-60-player.h
	player.x, player.y = player.startX, player.startY
	player.shoot.speed, player.shoot.size, player.shoot.recul, player.shoot.damage, player.shoot.gravity = 600, 15, 6, 7, 4
	player.shoot.img = love.graphics.newImage('images/img_tir_middle.png')
	player.shoot.timer = 10
	player.shoot.cadence = 30

	player.anim_walk_left = {}
	animation.new(player.anim_walk_left,'anim_middle_walk_left',6,9, true)
	player.anim_walk_right = {}
	animation.new(player.anim_walk_right,'anim_middle_walk_right',6,9, true)

	return player
end

function chara.load_small(player)
	player.vx, player.vy = 0, 0
	player.w, player.h, player.speed = 33, 36, 350
	player.startY = hauteurScreen-60-player.h
	player.x, player.y = player.startX, player.startY
	player.shoot.speed, player.shoot.size, player.shoot.recul, player.shoot.damage, player.shoot.gravity = 700, 6, 3, 3, 2
	player.shoot.img = love.graphics.newImage('images/img_tir_small.png')
	player.shoot.timer = 10
	player.shoot.cadence = 50

	player.anim_walk_left = {}
	animation.new(player.anim_walk_left,'anim_small_walk_left',6,12, true)
	player.anim_walk_right = {}
	animation.new(player.anim_walk_right,'anim_small_walk_right',6,12, true)

	return player
end	
---

-- PLAYERS --
function players.load()
	walk_state = 0
	shoot_state = 0
end	

function players.resetVelocity(player)
	for i = 1, len do
    	local col = cols[i]
    	if col.normal.y == -1 or col.normal.y == 1 then 
    		player.vy = 0
    	end	

    	if col.normal.y == -1 then 
    		player.jump = false	
    	end	
    end	
end	

function players.applyGravity(player, dt)
	player.vy = player.vy + gravity*dt
    player.x, player.y, cols, len = world:move(player,player.x,player.y + player.vy)
    players.resetVelocity(player)
end    

function players.applyRecul(player, dt)
	local friction = 60
	if math.sign(player.vx) == -1 then 
	    player.vx = player.vx + friction*dt
	    if player.vx > 0 then player.vx = 0 end
	elseif math.sign(player.vx) == 1 then 
		player.vx = player.vx - friction*dt
	    if player.vx < 0 then player.vx = 0 end
	end    
    player.x, player.y, cols, len = world:move(player,player.x+player.vx,player.y)
end	

function players.through_walls(player, dt)
	-- PLAFOND/SOL
	if player.y >= hauteurScreen then 
		player.y = 0 - player.h
		player.vx, player.vy = 0, 0
		world:update(player,player.x,player.y,player.w,player.h)
	elseif player.y+player.h <= 0 then 
		player.y = hauteurScreen
		player.vx = 0	
		world:update(player,player.x,player.y,player.w,player.h)
	end	
	
	-- MURS
	if player.x >= largeurScreen then 
		player.x = -player.w
		world:update(player,player.x,player.y,player.w,player.h)
	elseif player.x+player.w <= 0 then 
		player.x = largeurScreen
		world:update(player,player.x,player.y,player.w,player.h)
	end	
end

function players.movements_red(dt)
	-- RED movements // send to CLIENT
    local rx, ry = 0, 0 
    if love.keyboard.isDown('right') then 
	   	rx = red.speed*dt 
	   	animation.play(red.anim_walk_right,'loop',dt)
	   	red.state = 'right'
	   	walk_state = 1
	   	udp:sendto('right',client_IP,client_PORT)
    elseif love.keyboard.isDown('left') then 	
	   	rx = -red.speed*dt
	   	animation.play(red.anim_walk_left,'loop',dt)
	   	red.state = 'left'
	   	walk_state = 2
	   	udp:sendto('left',client_IP,client_PORT)
	elseif love.keyboard.isDown('down') then
	   	ry = red.speed*dt 
	   	walk_state = 3
	    udp:sendto('down',client_IP,client_PORT)
	else 
		red.anim_walk_left.timer = 1
		red.anim_walk_right.timer = 1
		walk_state = 0
	end

	-- gestion des tirs 
	--red.shoot.timer = red.shoot.timer - red.shoot.cadence*dt
	--if love.keyboard.isDown('space') and is_inside(red) and red.shoot.timer <= 0 then 
	--	tirs.create(red)
	--	shoot_state = 's'
	--	if red.state == 'right' then 
	--		red.vx = -red.shoot.recul
	--	elseif red.state == 'left' then 
	--		red.vx = red.shoot.recul
	--	end	
	--	red.shoot.timer = 10
	--else 
	-- 	shoot_state = 'e'	
	--end	
	---

	if rx ~= 0 or ry ~= 0 then
   		red.x, red.y, cols, len = world:move(red, red.x + rx, red.y + ry)
    end
end	

function players.movements_blue(dt)
	-- MOVEMENTS reception from blue 
	local bx, by = 0, 0
	if data == 'right' then
		bx = blue.speed*dt
		animation.play(blue.anim_walk_right,'loop',dt)
		blue.state = 'right'
	elseif data == 'left' then
		bx = -blue.speed*dt
		animation.play(blue.anim_walk_left,'loop',dt)
		blue.state = 'left'
	elseif data == 'down' then	 	
		by = blue.speed*dt
	else 
		blue.anim_walk_left.timer = 1
		blue.anim_walk_right.timer = 1
	end

	if data == 'jump' then 
		blue.vy = jumpVelocity
		blue.jump = true 
	end	

	if data == 'shoot' then 
		tirs.create(blue)
		if blue.state == 'right' then 
			blue.vx = -blue.shoot.recul
		elseif blue.state == 'left' then 
			blue.vx = blue.shoot.recul
		end
	end	

	if data == 'chara_big' then 
	elseif data == 'chara_middle' then 
	elseif data == 'chara_small' then 
	end	

	if bx ~= 0 or by ~= 0 then
   		blue.x, blue.y, cols_len = world:move(blue, blue.x + bx, blue.y + by)
    end
end		

function players.movements_blue_2(dt)
	if data then 
		local p = split(data,'-')

		if tonumber(p[3]) == 1 then
			animation.play(blue.anim_walk_right,'loop',dt)
			blue.state = 'right'
		elseif tonumber(p[3]) == 2 then
			animation.play(blue.anim_walk_left,'loop',dt)
			blue.state = 'left'	
		else 
			blue.anim_walk_left.timer = 1
			blue.anim_walk_right.timer = 1
		end

		if p[4] == 's' then 
			tirs.create(blue)
			if blue.state == 'right' then 
				blue.vx = -blue.shoot.recul
			elseif blue.state == 'left' then 
				blue.vx = blue.shoot.recul
			end
		end

		if tonumber(p[1]) ~= nil and tonumber(p[2]) ~= nil then 
			blue.x, blue.y = tonumber(p[1]), tonumber(p[2])	
		end

		blue.x, blue.y, cols_len = world:move(blue, blue.x, blue.y)
	end	
end

function players.movements_blue_3(dt)
	if data then 
		local p = split(data,'-')

		if p[1] == 'right' then
			bx = blue.speed*dt
			animation.play(blue.anim_walk_right,'loop',dt)
			blue.state = 'right'
		elseif p[1] == 'left' then
			bx = -blue.speed*dt
			animation.play(blue.anim_walk_left,'loop',dt)
			blue.state = 'left'
		elseif p[1] == 'down' then 
			by = blue.speed*dt
		else 	
			blue.anim_walk_left.timer = 1
			blue.anim_walk_right.timer = 1
		end

		if p[2] == 'jump' then 
			blue.vy = jumpVelocity
			blue.jump = true 
		end	

		if p[3] == 'shoot' then 
			tirs.create(blue)
			if blue.state == 'right' then 
				blue.vx = -blue.shoot.recul
			elseif blue.state == 'left' then 
				blue.vx = blue.shoot.recul
			end
		end

		if tonumber(p[1]) ~= nil and tonumber(p[2]) ~= nil then 
			blue.x, blue.y = tonumber(p[1]), tonumber(p[2])	
		end

		blue.x, blue.y, cols_len = world:move(blue, blue.x, blue.y)
	end	
end

function players.sante(dt) 
	if red.sante <= 0 then 
		red.sante = 0
		blue.round_gagne = blue.round_gagne + 1
		restart.round()
	end	

	if blue.sante <= 0 then 
		blue.sante = 0
		red.round_gagne = red.round_gagne + 1
		restart.round()
	end

	if blue.round_gagne >= 2 then 
		transition.to('menu_defeat')
	elseif red.round_gagne >= 2 then 
		transition.to('menu_victory')
	end	
end		

function players.update(dt)
    -- RED
	players.applyGravity(red,dt)
    if is_inside(red) then
    	players.applyRecul(red,dt) 
		players.movements_red(dt)
	end
	players.through_walls(red, dt)

	-- BLUE
	players.applyGravity(blue,dt)
	if is_inside(blue) then
		players.applyRecul(blue,dt)
		players.movements_blue(dt)
	end	
	players.through_walls(blue, dt)

	-- blue&red
    players.sante(dt)
end	

function players.draw()
	--setColor(178,89,72)
	--love.graphics.rectangle("line", red.x, red.y, red.w, red.h)
	--setColor(67,109,118)
	--love.graphics.rectangle("fill", blue.x, blue.y, blue.w, blue.h)
	setColor()

	if red.state == 'right' then 
		love.graphics.draw(red.anim_walk_right.img,red.anim_walk_right[math.floor(red.anim_walk_right.timer)],red.x,red.y,0,scale,scale)
	elseif red.state == 'left' then 
		love.graphics.draw(red.anim_walk_left.img,red.anim_walk_left[math.floor(red.anim_walk_left.timer)],red.x,red.y,0,scale,scale)
	end

	if blue.state == 'right' then 
		love.graphics.draw(blue.anim_walk_right.img,blue.anim_walk_right[math.floor(blue.anim_walk_right.timer)],blue.x,blue.y,0,scale,scale)
	elseif blue.state == 'left' then 
		love.graphics.draw(blue.anim_walk_left.img,blue.anim_walk_left[math.floor(blue.anim_walk_left.timer)],blue.x,blue.y,0,scale,scale)
	end
end	
---

-- BARRE DE VIE --
function barredevie.load()
	img_barredevie = love.graphics.newImage('images/img_barredevie.png')
	img_o_small = love.graphics.newImage('images/img_o_small.png')
	img_o_middle = love.graphics.newImage('images/img_o_middle.png')
	img_o_big = love.graphics.newImage('images/img_o_big.png')
	img_o_small2 = love.graphics.newImage('images/img_o_small2.png')
	img_o_middle2 = love.graphics.newImage('images/img_o_middle2.png')
	img_o_big2 = love.graphics.newImage('images/img_o_big2.png')
	round = 1
end

function barredevie.new(player,x)
	local barre_x, barre_y = x, 10

	setColor(178,89,72)
	love.graphics.rectangle('fill',barre_x+3,barre_y+3,174,9)

	local i = 0
	for i = 1, player.sante do 
		local width = 174/100 
		local x = (i-1) * width + barre_x+3
		setColor(206,181,120)
		setColor(72,178,119)
		love.graphics.rectangle('fill',x,barre_y+3,width,9)
	end	

	setColor()
	love.graphics.draw(img_barredevie,barre_x,barre_y,0,scale,scale)
end	

function barredevie.draw()
	barredevie.new(red,62)
	barredevie.new(blue,largeurScreen-62-183)

	if red.choice == 1 then 
		love.graphics.draw(img_o_big,10,10,0,2,2)
	elseif red.choice == 2 then 
		love.graphics.draw(img_o_middle,10,10,0,2,2)
	elseif red.choice == 3 then 
		love.graphics.draw(img_o_small,10,10,0,2,2)
	end	

	if blue.choice == 1 then 
		love.graphics.draw(img_o_big2,largeurScreen-50,10,0,2,2)
	elseif blue.choice == 2 then 
		love.graphics.draw(img_o_middle2,largeurScreen-50,10,0,2,2)
	elseif blue.choice == 3 then 
		love.graphics.draw(img_o_small2,largeurScreen-50,10,0,2,2)
	end		

	setColor(77,132,83) -- VERT
end		
--

-- GAME --
function game.load()
	players.load()
	arena.load()	
	animation.load()
	screenshake.load()
	barredevie.load()
end	

function game.update(dt)
	players.update(dt)
    tirs.update(red,dt)
    tirs.update(blue,dt)
    animation.update(dt)
    screenshake.update(dt)

    snd_bruitdejungle:stop()
	snd_africanbeat:play()
end	

function game.draw()
	screenshake.draw()
	players.draw()
	arena.draw()
	--cubes.draw()
	tirs.draw(red)
	tirs.draw(blue)
	animation.draw()
	barredevie.draw()
end

function game.keypressed(key)
	if key == 'up' and red.jump == false then 
		red.vy = jumpVelocity
		red.jump = true
		udp:sendto('jump',client_IP,client_PORT)
		sound.play(snd_jump)
	end	

	if key == 'space' and is_inside(red) then 
		tirs.create(red)
		shoot_state = 's'
		if red.state == 'right' then 
			red.vx = -red.shoot.recul
		elseif red.state == 'left' then 
			red.vx = red.shoot.recul
		end	
		udp:sendto('shoot',client_IP,client_PORT)
		sound.play(snd_hit)
	end	
end	
---

-- MENU --	
function menu.draw_title()
	setColor()
	love.graphics.draw(img_title,(largeurScreen/2)-(img_title:getWidth()/2)*scale,50,0,scale,scale)
	new_text_box('SPACE TO PLAY',0,290,'center')
	love.graphics.printf("1.0.0",720,hauteurScreen-20,largeurScreen,'left')
end	

function menu.keypressed_title(key)
	if key == 'space' then 
		searching_client = true 
		sound.play(snd_ui)
		transition.to('menu_connection')
	end
end	

function menu.draw_connection()
	if connected_to_client == false then 
		new_text_box('CONNECTION...',0,290,'center',true)
	else 
		new_text_box('CONNECTED!',0,290,'center')
	end	
end		

function menu.update_connection(dt)
	timer_connection = timer_connection - 10*dt

	if searching_client == true and data and timer_connection <= 0 then 
		if ip ~= nil and ip ~= timeout and port ~= nil then
			 client_IP = ip
			 client_PORT = port
		end	
		udp:sendto('Connection du client autorisée.', client_IP, client_PORT)
		connected_to_client = true 
		searching_client = false 
		sound.play(snd_ui)
		transition.to('menu_selection')
	end
end	

function menu.draw_selection()
	new_text_box('CHOOSE ONE',0,100,'center')

	setColor(246,227,107) -- JAUNE
	love.graphics.rectangle('fill', (largeurScreen/2)-500/2, 200+20, 500, 200-60)
	setColor()

	local x, y
	if red.choice == 1 then 
		x, y = 246, 247
		love.graphics.draw(img_selection_big,(largeurScreen/2)-500/2, 200,0,scale,scale)
	elseif red.choice == 2 then 
	    x, y = 398, 247
	    love.graphics.draw(img_selection_middle,(largeurScreen/2)-500/2, 200,0,scale,scale)
	elseif red.choice == 3 then 
		x, y = 550, 262
		love.graphics.draw(img_selection_small,(largeurScreen/2)-500/2, 200,0,scale,scale)
	end	
	setColor()

	love.graphics.draw(anim_flecheJoueur.img, anim_flecheJoueur[math.floor(anim_flecheJoueur.timer)], x, y,0,3,3)
end

function menu.keypressed_selection(key)
	if key == 'right' and red.choice < 3 then 
		red.choice = red.choice + 1
	elseif key == 'left' and red.choice > 1 then 
		red.choice = red.choice - 1	
	end	

	if key == 'space' then 
		sound.play(snd_ui)
		if red.choice == 1 then
			chara.load_big(red) 
		elseif red.choice == 2 then 
			chara.load_middle(red) 
		elseif red.choice == 3 then 
			chara.load_small(red)
		end 
		--world:add(blue, blue.x, blue.y, blue.w, blue.h)
		world:add(red, red.x, red.y, red.w, red.h)
		transition.to('menu_synchro')
	end
end

function menu.draw_synchro()
	-- 
	new_text_box('wait...',0,290,'center',true)
end	

function menu.update_synchro(dt)
	if red.choice == 1 then
		udp:sendto('chara_big',client_IP,client_PORT)
	elseif red.choice == 2 then 
		udp:sendto('chara_middle',client_IP,client_PORT)
	elseif red.choice == 3 then 
		udp:sendto('chara_small',client_IP,client_PORT)
	end

	if data == 'chara_big' then 
	    chara.load_big(blue)
	    blue.choice = 1
	    world:add(blue, blue.x, blue.y, blue.w, blue.h)	
    	transition.to('game')
	elseif data == 'chara_middle' then 
	    chara.load_middle(blue)
	    blue.choice = 2
	    world:add(blue, blue.x, blue.y, blue.w, blue.h)	
    	transition.to('game')
    elseif data == 'chara_small' then 
	    chara.load_small(blue)
	    blue.choice = 3
	    world:add(blue, blue.x, blue.y, blue.w, blue.h)	
    	transition.to('game')
	end
end	

function menu.draw_results()
	if gameScreen == 'menu_victory' then 	
		new_text_box('WINNER! space to quit',0,290,'center')
	elseif gameScreen == 'menu_defeat' then 	
		new_text_box('LOSER! space to quit',0,290,'center')
	end	
end		

function menu.keypressed_results(key)
	if key == 'space' then 
		sound.play(snd_ui)
		transition.to('menu_title')
		restart.game()
	end	
end	

function menu.load()
	img_title = love.graphics.newImage('images/img_title.png')
	img_selection_big = love.graphics.newImage('images/img_selection_big.png')
	img_selection_middle = love.graphics.newImage('images/img_selection_middle.png')
	img_selection_small = love.graphics.newImage('images/img_selection_small.png')
	timer_connection = 10
end	

function menu.update(dt)
	if gameScreen == 'menu_connection' then 
		menu.update_connection(dt)
	elseif gameScreen == 'menu_synchro' then 
		menu.update_synchro(dt)
    end	

	animation.play(anim_flecheJoueur, 'loop', dt)
	animation.play(anim_connection, 'loop', dt)

	snd_bruitdejungle:play()
	snd_africanbeat:stop()
end	

function menu.draw()
	setColor(77,132,83) -- VERT
	if gameScreen == 'menu_title' then 
		menu.draw_title()
	elseif gameScreen == 'menu_connection' then
		menu.draw_connection()	
	elseif gameScreen == 'menu_selection' then 
		menu.draw_selection()
	elseif gameScreen == 'menu_synchro' then 
		menu.draw_synchro()	
	elseif gameScreen == 'menu_victory' or gameScreen == 'menu_defeat' then	
		menu.draw_results()
	end		
end

function menu.keypressed(key)
	if gameScreen == 'menu_title' then
		menu.keypressed_title(key)
	elseif gameScreen == 'menu_selection' then 
		menu.keypressed_selection(key)
	elseif gameScreen == 'menu_victory' or gameScreen == 'menu_defeat' then 
		menu.keypressed_results(key)	
	end
end	
---

-- MAIN FUNCTIONS --
function love.load()
	love.window.setTitle('JungleVersus / SERVEUR')
	love.window.setMode(810, 600)
    largeurScreen, hauteurScreen = love.window.getMode()
    love.graphics.setFont(love.graphics.newFont("amstrad_cpc.ttf",12))
    love.graphics.setBackgroundColor(0.957, 0.882, 0.706)

	img_background = love.graphics.newImage('images/img_background.png')

	menu.load()
	game.load()
	sound.load()
	transition.load()
end

function love.update(dt)
	-- DATA reception from the client 
	data, ip, port = udp:receivefrom()

    if gameScreen == 'game' then 
    	game.update(dt)
    else 
    	menu.update(dt)	
    end	

    -- Envoie de la postion du joueur et des ses actions 
    --update_timer = update_timer + dt 
    --if update_timer > update_rate then -- Pour ne pas saturer le serveur/client 
    	--udp:sendto(tostring(red.x+red.vx)..'-'..tostring(red.y+red.vy)..'-'..tostring(walk_state)..'-'..shoot_state,client_IP,client_PORT)	
    	--update_timer =  update_timer - update_rate
    --end
    
    transition.update(dt)

	socket.sleep(0.01)
end				

function love.draw()
	love.graphics.draw(img_background,0,0,0,scale,scale)

	if gameScreen == 'game' then 
		game.draw()
	else
		menu.draw()
	end

	transition.draw()

	setColor(0,0,0)
	--love.graphics.print('red X: '..red.x..'    red Y : '..red.y,10,10)
	setColor()
end	

function love.keypressed(key)
	if transition.play == false then 
		if gameScreen == 'game' then 
			game.keypressed(key)
		else  
			menu.keypressed(key)
		end
	end		
end
---
