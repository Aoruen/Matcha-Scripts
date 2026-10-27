local previous=_G.__AoruenMatchaVFly
if previous and type(previous.stop)=="function" then pcall(previous.stop,true)end
local THIS_RUN={}
_G.__AoruenMatchaVFlyRun=THIS_RUN
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local RunService=game:GetService("RunService")
local O={Humanoid_SeatPart=0xF8,BasePart_Primitive=0x180,Model_PrimaryPart=0x248,Primitive_AssemblyLinearVelocity=0xE0,Primitive_AssemblyAngularVelocity=0xEC,Primitive_Rotation=0xB0,Camera_Rotation=0xC8,VehicleSeat_SteerFloat=0x21C,VehicleSeat_ThrottleFloat=0x220}
local THEO="https://offsets.imtheo.lol/offsets.txt"
local Theo={Humanoid_SeatPart="Humanoid::SeatPart",BasePart_Primitive="BasePart::Primitive",Model_PrimaryPart="Model::PrimaryPart",Primitive_AssemblyLinearVelocity="Primitive::AssemblyLinearVelocity",Primitive_AssemblyAngularVelocity="Primitive::AssemblyAngularVelocity",Primitive_Rotation="Primitive::Rotation",Camera_Rotation="Camera::Rotation",VehicleSeat_SteerFloat="VehicleSeat::SteerFloat",VehicleSeat_ThrottleFloat="VehicleSeat::ThrottleFloat"}
local Keys={"Humanoid_SeatPart","BasePart_Primitive","Model_PrimaryPart","Primitive_AssemblyLinearVelocity","Primitive_AssemblyAngularVelocity","Primitive_Rotation","Camera_Rotation","VehicleSeat_SteerFloat","VehicleSeat_ThrottleFloat"}
local cfg={dead=false,car=nil,lookedAt=0,loading=false}
local SESSION_PLACE=game.PlaceId
local SESSION_PLAYER=Players.LocalPlayer
local SESSION_JOB=""
local SESSION_GAME_ID=nil
local SESSION_GAME=game
local engineConnection=nil
local playerExitConnection=nil
local abs,sqrt,max,min=math.abs,math.sqrt,math.max,math.min
local V=Vector3.new
local function prop(o,k)if not o then return nil end local ok,v=pcall(function()return o[k]end)return ok and v or nil end
SESSION_JOB=prop(game,"JobId") or ""
SESSION_GAME_ID=prop(game,"GameId")
local function sessionAlive()
    if cfg.dead or _G.__AoruenMatchaVFlyRun~=THIS_RUN or game~=SESSION_GAME then return false end
    local place=prop(game,"PlaceId")
    if place~=SESSION_PLACE or prop(Players,"LocalPlayer")~=SESSION_PLAYER then return false end
    local job=prop(game,"JobId")
    if type(SESSION_JOB)=="string" and SESSION_JOB~="" and type(job)=="string" and job~="" and job~=SESSION_JOB then return false end
    local gameId=prop(game,"GameId")
    if SESSION_GAME_ID~=nil and gameId~=nil and SESSION_GAME_ID~=gameId then return false end
    local ok,loaded=pcall(function()return game:IsLoaded()end)
    if ok and loaded==false then return false end
    return true
end
local function valid(a)return type(a)=="number"and a==a and a>=0x10000 and a<0x800000000000 and a%1==0 end
local function safeNumber(a,cap)return type(a)=="number"and a==a and abs(a)<(cap or 1e7)end
local function read(t,a)if cfg.dead or not valid(a)then return nil end local ok,v=pcall(memory_read,t,a)return ok and v or nil end
local function ptr(a)local p=read("uintptr_t",a)return valid(p)and p or nil end
local function vec(a)
    local x,y,z=read("float",a),read("float",a+4),read("float",a+8)
    if not safeNumber(x)or not safeNumber(y)or not safeNumber(z)then return nil end
    return V(x,y,z)
end
local function wvec(a,v)
    if cfg.dead or not sessionAlive() or not valid(a)or not v or not safeNumber(v.X,1e6)or not safeNumber(v.Y,1e6)or not safeNumber(v.Z,1e6)then return false end
    return pcall(function()memory_write("float",a,v.X)memory_write("float",a+4,v.Y)memory_write("float",a+8,v.Z)end)
end
local function wfloat(a,n)if cfg.dead or not sessionAlive() or not valid(a)or not safeNumber(n)then return false end return pcall(memory_write,"float",a,n)end
local function dot(a,b)return a.X*b.X+a.Y*b.Y+a.Z*b.Z end
local function cross(a,b)return V(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X)end
local function near(a,b,low)
    if not a or not b then return false end
    local x,y,z=a.X-b.X,a.Y-b.Y,a.Z-b.Z
    return sqrt(x*x+y*y+z*z)<=max(low or .05,b.Magnitude*.06)
end
local function hx(n)return string.format("0x%X",n or 0)end
local function parse(s)
    local t={}
    if type(s)~="string"then return t end
    for k,v in s:gmatch("([%w_:]+)%s*=%s*0[xX]([%x]+)")do t[k]=tonumber(v,16)end
    return t
end
local function applyRegular(parsed,requireAll)
    local found,updates=0,{}
    for _,key in ipairs(Keys)do
        local v=parsed[Theo[key]]
        if type(v)=="number"and v>=0x20 and v<=0x4000 and v%4==0 then updates[key]=v found=found+1 end
    end
    if requireAll and found~=#Keys then return false,found,false end
    if found==0 then return false,0,false end
    local changed=false
    for key,v in pairs(updates)do if O[key]~=v then changed=true end O[key]=v end
    if changed then cfg.car=nil end
    return true,found,changed
end
local function reloadTheo()
    if cfg.loading then return false end
    cfg.loading=true
    local ok,raw=pcall(httpget,THEO)
    if cfg.dead then cfg.loading=false return false end
    local accepted,count,changed=false,0,false
    if ok and type(raw)=="string"and#raw>0 then accepted,count,changed=applyRegular(parse(raw),true)end
    cfg.loading=false
    return changed
end
local function findAddress(address)
    if not valid(address)then return nil end
    local ok,all=pcall(function()return Workspace:GetDescendants()end)
    if not ok or type(all)~="table"then return nil end
    for _,x in ipairs(all)do if prop(x,"Address")==address then return x end end
    return nil
end
local function isPart(x)
    local cls=prop(x,"ClassName")
    if cls=="Part" or cls=="MeshPart" or cls=="VehicleSeat" or cls=="Seat" or cls=="UnionOperation" or cls=="WedgePart" or cls=="TrussPart" then return true end
    local ok,result=pcall(function()return x:IsA("BasePart")end)
    return ok and result==true
end
local function primitive(x)
    local a=prop(x,"Address")
    return valid(a)and ptr(a+O.BasePart_Primitive)or nil
end
local function getCandidateParts(seat)
    local result,seen={},{}
    local function add(part,model,priority)
        local address=prop(part,"Address")
        if not isPart(part)or not valid(address)or seen[address]or #result>=350 then return end
        local p=primitive(part)
        if not p then return end
        seen[address]=true
        result[#result+1]={part=part,model=model,primitive=p,name=tostring(prop(part,"Name")or""),priority=priority or 0}
    end
    local nearest=nil
    add(seat,nil,5)
    local assemblyRoot=prop(seat,"AssemblyRootPart")
    if isPart(assemblyRoot) then add(assemblyRoot,prop(assemblyRoot,"Parent"),150) end
    local connectedOk,connected=pcall(function()return seat:GetConnectedParts(true)end)
    if connectedOk and type(connected)=="table"then
        for _,part in ipairs(connected)do
            local root=prop(part,"AssemblyRootPart")
            if isPart(root)then add(root,prop(root,"Parent"),135)end
            if isPart(part)then add(part,prop(part,"Parent"),35)end
        end
    end
    local ancestor=prop(seat,"Parent")
    local levels=0
    while ancestor and levels<6 do
        if prop(ancestor,"ClassName")=="Model" then
            if not nearest then nearest=ancestor end
            local primary=prop(ancestor,"PrimaryPart")
            if not isPart(primary)then
                local ma=prop(ancestor,"Address")
                local ra=valid(ma)and ptr(ma+O.Model_PrimaryPart)or nil
                if ra then
                    local ok,all=pcall(function()return ancestor:GetDescendants()end)
                    if ok and type(all)=="table"then
                        for _,x in ipairs(all)do if prop(x,"Address")==ra then primary=x break end end
                    end
                end
            end
            if primary then add(primary,ancestor,100-levels)end
            local ok,all=pcall(function()return ancestor:GetDescendants()end)
            if ok and type(all)=="table"then
                for _,x in ipairs(all)do
                    if isPart(x)then
                        local n=tostring(prop(x,"Name")or""):lower()
                        local priority=(n:find("chassis",1,true)or n:find("body",1,true)or n:find("main",1,true)or n:find("root",1,true)or n:find("base",1,true)or n:find("frame",1,true))and 60 or 10
                        if n:find("animate",1,true)or n:find("fake",1,true)then priority=priority-45 end
                        if prop(x,"AssemblyRootPart")==x then priority=priority+40 end
                        add(x,ancestor,priority-levels)
                    end
                end
            end
        end
        ancestor=prop(ancestor,"Parent")
        levels=levels+1
    end
    table.sort(result,function(a,b)
        if a.priority~=b.priority then return a.priority>b.priority end
        return a.name<b.name
    end)
    while #result>64 do table.remove(result)end
    return result,nearest
end
local function car()
    if cfg.dead then return nil,"Script stopped" end
    local lp=Players.LocalPlayer
    local ch=prop(lp,"Character")
    local h=ch and ch:FindFirstChildOfClass("Humanoid")
    local ha=prop(h,"Address")
    if not valid(ha)then cfg.car=nil return nil,"Humanoid not resolved"end
    local seat=prop(h,"SeatPart")
    local sa=prop(seat,"Address")
    if not valid(sa)then sa=ptr(ha+O.Humanoid_SeatPart)end
    if not valid(sa)then
        cfg.car=nil
        return nil,"Humanoid SeatPart is nil/invalid; verify you are sitting in a vehicle"
    end
    local cached=cfg.car
    if cached and cached.character~=ch then cfg.car=nil cached=nil end
    if cached and cached.seatAddress==sa and prop(cached.seat,"Address")==sa then
        local ra=prop(cached.root,"Address")
        if valid(ra)and ptr(ra+O.BasePart_Primitive)==cached.primitive then return cached end
    end
    if not seat or prop(seat,"Address")~=sa then
        if cached and cached.seatAddress==sa then seat=cached.seat else
            if tick()-cfg.lookedAt<0.75 then return nil,"Seat instance lookup cooling down"end
            cfg.lookedAt=tick()
            seat=findAddress(sa)
        end
    end
    if not seat then return nil,"Seat address "..hx(sa).." not found among workspace instances"end
    if not prop(seat,"Parent") then cfg.car=nil return nil,"Seat no longer parented"end
    local supported,inside=pcall(function()return seat:IsDescendantOf(Workspace)end)
    if supported and inside==false then cfg.car=nil return nil,"Seat detached from workspace"end
    local sp=primitive(seat)
    if not sp then return nil,"Seat primitive missing (BasePart::Primitive="..hx(O.BasePart_Primitive)..")"end
    local candidates,model=getCandidateParts(seat)
    if #candidates==0 then return nil,"Seat resolved but no valid part primitives were found"end
    local selected=candidates[1]
    local c={seat=seat,seatAddress=sa,seatPrimitive=sp,model=model,root=selected.part,
        primitive=selected.primitive,modelName=tostring(prop(model,"Name")or prop(seat,"Name")or""),
        rootName=selected.name,candidates=candidates,character=ch}
    cfg.car=c
    return c
end
local function selectRoot(c,x)
    c.root=x.part
    c.primitive=x.primitive
    c.rootName=x.name
    cfg.car=c
end
local function getPointers(p)
    if cfg.dead then return {} end
    local list={}
    for off=0,0x500,8 do
        local v=ptr(p+off)
        if v and abs(v-p)>0x500 then list[#list+1]={off=off,address=v}end
    end
    return list
end
local function fieldHits(object,reference,tol)
    local results={}
    for off=0x40,0x180,4 do if cfg.dead then return results end if near(vec(object+off),reference,tol)then results[#results+1]=off end end
    return results
end
local function scanAngular(s)
    local c=car()
    if not c or c.primitive~=s.primitive or c.seatAddress~=s.seatAddress then return false,"Remain seated in the same vehicle"end
    local angular=vec(c.primitive+O.Primitive_AssemblyAngularVelocity)
    if not angular or angular.Magnitude<0.2 then return false,"Turn/spin the vehicle until angular speed exceeds 0.2"end
    local aa,bb=ptr(c.primitive+s.A.ptr),ptr(c.primitive+s.B.ptr)
    if not aa or not bb or aa==bb then return false,"Solver pointers unavailable"end
    s.A.address,s.B.address=aa,bb
    local a,b=fieldHits(aa,angular,0.05),fieldHits(bb,angular,0.05)
    if#a==0 or#b==0 then return false,"Angular fields not found; keep turning and retry"end
    s.A.angular,s.B.angular=a[1],b[1]
    return true,nil
end
local SEED={PlaceId=3351674303,VehicleName="SweetDreamsLUA",RootName="PlateCenter",SolverPtrA=0x18,SolverLinearVelA=0xD0,SolverAngularVelA=0xDC,SolverPtrB=0x140,SolverLinearVelB=0xA4,SolverAngularVelB=0xB0}
local function bindSolver(c,s,strict)
    if not s or c.primitive~=s.primitive or c.seatAddress~=s.seatAddress then return nil,"Vehicle changed"end
    local a,b=ptr(c.primitive+s.A.ptr),ptr(c.primitive+s.B.ptr)
    if not a or not b or a==b or abs(a-c.primitive)<0x500 or abs(b-c.primitive)<0x500 then return nil,"Solver pointers unavailable"end
    local la,lb=vec(a+s.A.linear),vec(b+s.B.linear)
    local aa,ab=vec(a+s.A.angular),vec(b+s.B.angular)
    if not la or not lb or not aa or not ab then return nil,"Solver buffers unreadable"end
    if la.Magnitude>10000 or lb.Magnitude>10000 or aa.Magnitude>500 or ab.Magnitude>500 then return nil,"Solver buffer fields implausible"end
    if strict then
        local ref=vec(c.primitive+O.Primitive_AssemblyLinearVelocity)
        local av=vec(c.primitive+O.Primitive_AssemblyAngularVelocity)
        if ref and ref.Magnitude>5 and (not near(la,ref,2.5) or not near(lb,ref,2.5)) then return nil,"Linear solver tracking mismatch"end
        if av and av.Magnitude>0.3 and (not near(aa,av,0.2) or not near(ab,av,0.2)) then return nil,"Angular solver tracking mismatch"end
    end
    local changed=(s.A.address~=a or s.B.address~=b)
    s.A.address,s.B.address=a,b
    return true,changed
end
local function fromOffsets(c,offsets,rootName,source)
    if not offsets then return nil,"No known layout"end
    for _,key in ipairs({"SolverPtrA","SolverLinearVelA","SolverAngularVelA","SolverPtrB","SolverLinearVelB","SolverAngularVelB"})do
        local v=offsets[key]
        local pointer=key=="SolverPtrA"or key=="SolverPtrB"
        if type(v)~="number"or v<(pointer and 0 or 0x40)or v>(pointer and 0x500 or 0x180)or v%(pointer and 8 or 4)~=0 then
            return nil,"Invalid solver layout: "..key
        end
    end
    if offsets.SolverPtrA==offsets.SolverPtrB then return nil,"Solver pointers overlap"end
    local prev,prevRoot,prevName=c.primitive,c.root,c.rootName
    for _,x in ipairs(c.candidates)do
        if x.name==rootName then
            selectRoot(c,x)
            local s={primitive=c.primitive,seatAddress=c.seatAddress,modelName=c.modelName,rootName=c.rootName,
                A={ptr=offsets.SolverPtrA,linear=offsets.SolverLinearVelA,angular=offsets.SolverAngularVelA},
                B={ptr=offsets.SolverPtrB,linear=offsets.SolverLinearVelB,angular=offsets.SolverAngularVelB},source=source}
            local ok=bindSolver(c,s,false)
            if ok then return s end
        end
    end
    c.primitive,c.root,c.rootName=prev,prevRoot,prevName
    return nil,"Solver fields did not validate on the current vehicle"
end
local function knownLayout(c)
    if tonumber(game.PlaceId)~=SEED.PlaceId or c.modelName~=SEED.VehicleName then return nil end
    local s=fromOffsets(c,SEED,SEED.RootName,"confirmed-log")
    return s
end
local sessionLayouts={}
local function layoutKey(c)
    return tostring(game.PlaceId).."/"..c.modelName
end
local function offsetsFingerprint()
    local t={}
    for _,k in ipairs(Keys)do t[#t+1]=tostring(O[k])end
    return table.concat(t,":")
end
local function rememberLayout(c,s)
    local item={RootName=s.rootName,regular=offsetsFingerprint()}
    item.SolverPtrA=s.A.ptr item.SolverLinearVelA=s.A.linear item.SolverAngularVelA=s.A.angular
    item.SolverPtrB=s.B.ptr item.SolverLinearVelB=s.B.linear item.SolverAngularVelB=s.B.angular
    sessionLayouts[layoutKey(c)]=item
end
local function recalledLayout(c)
    local item=sessionLayouts[layoutKey(c)]
    if not item or item.regular~=offsetsFingerprint()then return nil end
    return fromOffsets(c,item,item.RootName,"session-memory")
end
local state={running=true,ready=nil,scanning=false,attemptAt=0,calibrationCount=0,attempts=0,failures=0,
    status="Automatic setup enabled - sit in a vehicle",t=0,lastStatus="",lastError=0,bufferEvents=0,activeSeat=0,activeCharacter=nil,lastGate=nil,diagnosticAt=0,scanJob=nil}
local ID={enabled="aoruen_vfly_enable",hotkey="aoruen_vfly_hotkey",speed="aoruen_vfly_speed",follow="aoruen_vfly_follow",roll="aoruen_vfly_roll",max="aoruen_vfly_maxrot"}
local lastKeybindWidget=nil
local function get(id,default)
    if cfg.dead then return default end
    local ok,v=pcall(UI.GetValue,id)
    if ok and v~=nil then return v end
    if id==ID.hotkey and lastKeybindWidget then
        local worked,active=pcall(function()return lastKeybindWidget:IsEnabled()end)
        if worked and type(active)=="boolean" then return active end
    end
    return default
end
local function status(msg)
    state.status=msg
    if state.lastStatus~=msg then
        state.lastStatus=msg
    end
end
local function basis(cf)
    if not cf then return nil end
    local f,r,u=prop(cf,"LookVector"),prop(cf,"RightVector"),prop(cf,"UpVector")
    if f and r and u then return f,r,u end
end
local function rawBasis(address)
    local x,y,z=vec(address),vec(address+0xC),vec(address+0x18)
    if not x or not y or not z then return nil end
    local r,u,f=V(x.X,y.X,z.X),V(x.Y,y.Y,z.Y),V(-x.Z,-y.Z,-z.Z)
    if r.Magnitude<0.001 or u.Magnitude<0.001 or f.Magnitude<0.001 then return nil end
    return f.Unit,r.Unit,u.Unit
end
local function cameraBasis()
    local cam=prop(Workspace,"CurrentCamera")
    if not cam then return nil end
    local f,r,u=basis(prop(cam,"CFrame"))
    if f then return f,r,u end
    local address=prop(cam,"Address")
    if valid(address)then return rawBasis(address+O.Camera_Rotation)end
end
local function lockedCamera()
    local f,cr=cameraBasis()
    if not f then return nil end
    local up=V(0,1,0)
    local r=cross(f,up)
    if r.Magnitude<0.01 then
        r=cr and V(cr.X,0,cr.Z)or V(1,0,0)
        if r.Magnitude<0.01 then r=V(1,0,0)end
    end
    r=r.Unit
    local u=cross(r,f)
    if u.Magnitude<0.01 then return nil end
    return f.Unit,r,u.Unit
end
local function held(vk)local ok,v=pcall(iskeypressed,vk)return ok and v==true end
local function velocity()
    local f,r,u=lockedCamera()
    if not f then return nil end
    local fb=(held(0x57)and 1 or 0)-(held(0x53)and 1 or 0)
    local lr=(held(0x44)and 1 or 0)-(held(0x41)and 1 or 0)
    local qe=(held(0x45)and 2 or 0)-(held(0x51)and 2 or 0)
    if fb==0 and lr==0 and qe==0 then return V(0,0,0)end
    return (f*fb+r*lr+u*((fb+qe)*0.2))*(get(ID.speed,1)*50)
end
local function angular(p)
    local tf,tr,tu=lockedCamera()
    local f,r,u=rawBasis(p+O.Primitive_Rotation)
    if not tf or not f then return nil end
    local e=(cross(f,tf)+cross(r,tr)+cross(u,tu))*0.5
    local roll=dot(e,tf)
    e=e+tf*roll*(get(ID.roll,4)-1)
    if e.Magnitude<0.0001 then return V(0,0,0)end
    local av=e*get(ID.follow,20)
    local limit=get(ID.max,18)
    return av.Magnitude>limit and av.Unit*limit or av
end
local function stopSeatSteering(c)
    local addr=prop(c.seat,"Address")
    if valid(addr)then
        wfloat(addr+O.VehicleSeat_SteerFloat,0)
        wfloat(addr+O.VehicleSeat_ThrottleFloat,0)
    end
end
local function directFly(c,lv,av)
    stopSeatSteering(c)
    local p=c.primitive
    local sp=c.seatPrimitive
    if valid(p)then
        wvec(p+O.Primitive_AssemblyLinearVelocity,lv)
        wvec(p+O.Primitive_AssemblyAngularVelocity,av)
    end
    if valid(sp)and sp~=p then
        wvec(sp+O.Primitive_AssemblyLinearVelocity,lv)
        wvec(sp+O.Primitive_AssemblyAngularVelocity,av)
    end
end
local function describeActive(s)
    state.ready=s
    state.failures=0
    state.bufferEvents=0
    status("VFly ready ("..(s.source or "auto").."); no driving required")
end
local function resolveForSetup()
    local c,reason=car()
    if not c then return nil,reason end
    if state.activeSeat~=c.seatAddress or state.activeCharacter~=c.character then
        state.activeSeat=c.seatAddress
        state.ready=nil
        state.failures=0
        state.attemptAt=0
        state.calibrationCount=0
        state.attempts=0
    end
    return c
end
local function tryCached(c)
    local remembered=recalledLayout(c)
    if remembered then describeActive(remembered)return true end
    local known=knownLayout(c)
    if known then
        rememberLayout(c,known)
        describeActive(known)
        return true
    end
    return false
end
local function pulse(c,kind)
    if cfg.dead or not c or not prop(c.seat,"Address")then return false end
    local isAng=kind=="angular"
    local off=isAng and O.Primitive_AssemblyAngularVelocity or O.Primitive_AssemblyLinearVelocity
    local target=isAng and c.primitive or c.seatPrimitive
    local v=isAng and V(0,1.7,0)or V(0,0,27)
    local old=vec(target+off)
    if not old then return false end
    if (not isAng and old.Magnitude>6)or(isAng and old.Magnitude>0.4)then return true end
    if not isAng then
        pcall(function()c.seat.AssemblyLinearVelocity=v end)
    end
    return wvec(target+off,v)
end
local function cancelScan()
    state.scanning=false
    state.scanJob=nil
end
local function scanBegin(c)
    local shared={}
    for _,x in ipairs(getPointers(c.seatPrimitive)) do shared[x.address]=true end
    state.scanJob={phase="linear",seat=c.seatAddress,character=c.character,seatPrimitive=c.seatPrimitive,
        candidates=c.candidates,index=1,shared=shared,matches={},ptrList=nil,ptrIndex=1,ref=nil,
        root=nil,best=nil,bestScore=-1,fast=0,cycles=0,angularAttempt=0,nextAt=0,pulsed=false}
    state.scanning=true
end
local function finishCandidate(job)
    local candidate=job.candidates[job.index]
    local matches=job.matches
    local sharedMatches={}
    for _,x in ipairs(matches) do if x.shared then sharedMatches[#sharedMatches+1]=x end end
    local chosen=(#sharedMatches>=2)and sharedMatches or matches
    if #chosen>=2 then
        table.sort(chosen,function(a,b)
            if a.shared~=b.shared then return a.shared end
            if a.hits~=b.hits then return a.hits>b.hits end
            return a.ptr<b.ptr
        end)
        local score=(#sharedMatches>=2 and 300 or 100)+min(#chosen,8)*5+chosen[1].hits+chosen[2].hits+candidate.priority/100
        if score>job.bestScore then
            local picked={chosen[1],chosen[2]}
            table.sort(picked,function(a,b)return a.ptr<b.ptr end)
            job.best={candidate=candidate,A=picked[1],B=picked[2]}
            job.bestScore=score
        end
    end
    job.index=job.index+1
    job.ptrList=nil
    job.ptrIndex=1
    job.matches={}
end
local function scanSlice(job)
    local work=0
    while work<3 and job.index<=#job.candidates do
        local candidate=job.candidates[job.index]
        if not job.ptrList then
            local reference=vec(candidate.primitive+O.Primitive_AssemblyLinearVelocity)
            if not reference or reference.Magnitude<6 then
                job.index=job.index+1
            else
                job.fast=job.fast+1
                job.ref=reference
                job.ptrList=getPointers(candidate.primitive)
                job.matches={}
                job.seen={}
                job.ptrIndex=1
            end
            work=work+1
        else
            local x=job.ptrList[job.ptrIndex]
            if not x then
                finishCandidate(job)
            else
                job.ptrIndex=job.ptrIndex+1
                if not job.seen[x.address] then
                    job.seen[x.address]=true
                    local hits=fieldHits(x.address,job.ref,1)
                    if #hits>0 then job.matches[#job.matches+1]={ptr=x.off,address=x.address,linear=hits[1],hits=#hits,shared=job.shared[x.address]==true}end
                end
            end
            work=work+1
        end
    end
    return job.index>#job.candidates
end
local function failedScan(job,c)
    if not job.pulsed then
        if pulse(c,"linear") then
            job.pulsed=true
            job.phase="pulse_wait"
            job.nextAt=tick()+0.07
            return
        end
    end
    state.attempts=state.attempts+1
    state.attemptAt=tick()
    cancelScan()
end
local function finishLinear(job,c)
    if not job.best then return failedScan(job,c) end
    local best=job.best
    selectRoot(c,best.candidate)
    job.root={primitive=c.primitive,seatAddress=c.seatAddress,modelName=c.modelName,rootName=c.rootName,A=best.A,B=best.B}
    job.phase="angular"
    job.angularAttempt=0
    job.nextAt=0
end
local function stepCalibration(c)
    local job=state.scanJob
    if not job or cfg.dead then return end
    if job.seat~=c.seatAddress or job.character~=c.character or job.seatPrimitive~=c.seatPrimitive then
        cancelScan() return
    end
    if not sessionAlive() then cancelScan() return end
    if job.phase=="linear" then
        if scanSlice(job) then finishLinear(job,c) end
    elseif job.phase=="pulse_wait" then
        if tick()<job.nextAt then return end
        job.phase="linear"
        job.index=1 job.best=nil job.bestScore=-1 job.fast=0 job.ptrList=nil job.ptrIndex=1 job.matches={}
    elseif job.phase=="angular" then
        if tick()<job.nextAt then return end
        if job.angularAttempt>=5 then
            state.attempts=state.attempts+1 state.attemptAt=tick() cancelScan() return
        end
        local av=vec(job.root.primitive+O.Primitive_AssemblyAngularVelocity)
        if not av or av.Magnitude<0.25 then
            pulse(c,"angular")
            job.nextAt=tick()+0.12
            job.angularAttempt=job.angularAttempt+1
            return
        end
        local passed=scanAngular(job.root)
        if passed then
            local current=car()
            if current and current.seatAddress==job.seat and current.primitive==job.root.primitive and bindSolver(current,job.root,false)then
                job.root.source="auto-calibrated"
                rememberLayout(current,job.root)
                describeActive(job.root)
                cancelScan()
                return
            end
        end
        job.angularAttempt=job.angularAttempt+1
        job.nextAt=tick()+0.15
    end
end
local function autoSetup()
    if cfg.dead or state.scanning or cfg.loading or not sessionAlive() then return end
    local c=resolveForSetup()
    if not c or state.ready then return end
    if state.attemptAt>0 and tick()-state.attemptAt<(state.attempts>=3 and 25 or 9) then return end
    if state.attempts>=3 then state.attempts=0 end
    if tryCached(c)then return end
    if not get(ID.enabled,false)then return end
    scanBegin(c)
end
local function refreshTheo()
    local changed=reloadTheo()
    if cfg.dead then return end
    if changed then
        state.ready=nil
        state.attemptAt=0
        status("Regular offsets changed; automatic setup will revalidate")
    end
end
local function runtime(dt)
    if cfg.dead or not state.running then return end
    if not sessionAlive() then return end
    state.t=state.t+(type(dt)=="number"and dt or 0.016)
    if state.t>=0.35 then
        state.t=0
        local c=car()
        if not c then
            if state.ready then state.ready=nil status("Left vehicle; waiting for next seat")end
            state.activeSeat=0
            state.activeCharacter=nil
            cancelScan()
        else
            if state.activeSeat~=c.seatAddress then
                state.ready=nil
                state.activeSeat=c.seatAddress
                state.activeCharacter=c.character
                state.attemptAt=0
                state.attempts=0
                cancelScan()
            end
            if not state.ready then autoSetup()end
        end
    end
    if state.scanning then
        local current=car()
        if current then stepCalibration(current)else cancelScan()end
    end
    local master=get(ID.enabled,false)==true
    local hot=get(ID.hotkey,false)==true
    local active=master and hot
    if state.lastGate~=active then
        state.lastGate=active
        if active then status("Hotkey ACTIVE; executing the original velocity writer")
        elseif master then status("VFly armed; press V to activate flight")
        else status("VFly disabled (master toggle off)")end
    end
    if not active then return end
    local c=car()
    if not c then return end
    local lv=velocity()
    local av=angular(c.primitive)
    if not lv or not av then return end
    local ready=state.ready
    if ready and c.primitive==ready.primitive and c.seatAddress==ready.seatAddress then
        local good=bindSolver(c,ready,false)
        if good then
            stopSeatSteering(c)
            wvec(ready.A.address+ready.A.linear,lv)
            wvec(ready.B.address+ready.B.linear,lv)
            wvec(c.primitive+O.Primitive_AssemblyLinearVelocity,lv)
            wvec(ready.A.address+ready.A.angular,av)
            wvec(ready.B.address+ready.B.angular,av)
            wvec(c.primitive+O.Primitive_AssemblyAngularVelocity,av)
            state.failures=0
            return
        end
        state.failures=state.failures+1
        if state.failures>45 then
            state.ready=nil
            state.attemptAt=0
            status("Solver invalid after repeated retries; automatic recovery queued")
        end
    elseif ready then
        state.ready=nil
        state.attemptAt=0
    end
    directFly(c,lv,av)
end
pcall(refreshTheo)
pcall(function()UI.RemoveTab("VFly")end)
UI.AddTab("VFly",function(tab)
    if cfg.dead then return end
    local main=tab:Section("Vehicle Fly","Left")
    main:Toggle(ID.enabled,"Enable VFly",false)
    local kb=main:Keybind(ID.hotkey,0x56,"toggle")
    lastKeybindWidget=kb
    kb:AddToHotkey("VFly",ID.enabled)
    main:SliderFloat(ID.speed,"VFly Speed",0.1,20,1,"%.1f")
    main:SliderFloat(ID.follow,"Camera Follow",1,50,20,"%.1f")
    main:SliderFloat(ID.roll,"Roll Lock",1,8,4,"%.1f")
    main:SliderFloat(ID.max,"Max Rotation Speed",1,40,18,"%.1f")
end)
local function stop(removeUI)
    if cfg.dead then return end
    local canRemoveUI=removeUI and sessionAlive()
    cfg.dead=true
    state.running=false
    state.ready=nil
    cancelScan()
    cfg.car=nil
    local hb,pe=engineConnection,playerExitConnection
    engineConnection=nil playerExitConnection=nil
    if hb then pcall(function()hb:Disconnect()end)end
    if pe then pcall(function()pe:Disconnect()end)end
    if canRemoveUI then pcall(function()UI.RemoveTab("VFly")end)end
    if _G.__AoruenMatchaVFlyRun==THIS_RUN then _G.__AoruenMatchaVFlyRun=nil end
    if _G.__AoruenMatchaVFly and _G.__AoruenMatchaVFly.stop==stop then _G.__AoruenMatchaVFly=nil end
end
_G.__AoruenMatchaVFly={stop=stop,run=THIS_RUN}
engineConnection=RunService.Heartbeat:Connect(function(dt)
    if cfg.dead then return end
    if not sessionAlive() then stop(false)return end
    pcall(runtime,dt)
end)
pcall(function()
    playerExitConnection=Players.PlayerRemoving:Connect(function(p)
        if p==SESSION_PLAYER then stop(false)end
    end)
end)
if sessionAlive() then
    pcall(function()notify("Automatic VFly ready - sit in a vehicle","Made By Aoruen :3",4)end)
else
    stop(false)
end
