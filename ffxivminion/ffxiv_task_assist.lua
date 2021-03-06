ffxiv_task_assist = inheritsFrom(ml_task)
ffxiv_task_assist.name = "LT_ASSIST"

function ffxiv_task_assist.Create()
    local newinst = inheritsFrom(ffxiv_task_assist)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_assist members
    newinst.name = "LT_ASSIST"
    newinst.targetid = 0
    
    return newinst
end

function ffxiv_task_assist:Init()
    --init Process() cnes
	local ke_pressConfirm = ml_element:create( "ConfirmDuty", c_pressconfirm, e_pressconfirm, 10 )
    self:add(ke_pressConfirm, self.process_elements)
  
    self:AddTaskCheckCEs()
end

function ffxiv_task_assist:GetHealingTarget()
    local target = nil
    if ( gAssistMode == "LowestHealth") then	
        local target = GetBestHealTarget()		
    
    elseif ( gAssistMode == "Closest" ) then	
        local target = GetClosestHealTarget()	
    end
    
    if ( target~=nil and target.hp.percent < SkillMgr.GetHealSpellHPLimit() ) then
        return target
    end
    return nil
end

function ffxiv_task_assist:GetAttackTarget()
    local target = nil
    if ( gAssistMode == "LowestHealth") then	
        local el = EntityList("lowesthealth,alive,attackable,maxdistance="..tostring(ml_global_information.AttackRange))
        if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                target = e
            end
        end	
    
    elseif ( gAssistMode == "Closest" ) then	
        local el = EntityList("shortestpath,alive,attackable,maxdistance="..tostring(ml_global_information.AttackRange))
        if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                target = e
            end
        end	
    end
    
    return target
end


function ffxiv_task_assist:Process()

    local target = Player:GetTarget()
    
    if ( gAssistMode ~= "None" ) then
        local newTarget = nil
        
        if ( gAssistPriority == "Healer" ) then
            newTarget = ffxiv_task_assist:GetHealingTarget()
            if ( newTarget == nil ) then
                newTarget = ffxiv_task_assist:GetAttackTarget()				
            end		

        elseif ( gAssistPriority == "Damage" ) then
            newTarget = ffxiv_task_assist:GetAttackTarget()
            if ( newTarget == nil ) then
                newTarget = ffxiv_task_assist:GetHealingTarget()				
            end			
        end
        
        if ( newTarget ~= nil and (not target or newTarget.id ~= target.id)) then
            target = newTarget
        end
    end	

    if 	( target and target.alive and (target.attackable or target.chartype==2 or target.chartype==5 or target.chartype==4) and target.distance2d <= 30 ) then
        local pos = target.pos
        
        --Player:SetFacing(pos.x,pos.y,pos.z)
        Player:SetTarget(ml_task_hub:CurrentTask().targetid)
        local cast = false
        
        if (Player.hp.percent < 75 )then
            cast = SkillMgr.Cast( Player )
        end
        if not cast then			
            SkillMgr.Cast( target )
        end	
    end
	
	    -- last run the regular cne elements

    if (TableSize(self.process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.process_elements)
		if (self:superClass() and TableSize(self:superClass().process_elements) > 0) then
			ml_cne_hub.eval_elements(self:superClass().process_elements)
		end
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

function ffxiv_task_assist:OnSleep()

end

function ffxiv_task_assist:OnTerminate()

end

function ffxiv_task_assist:IsGoodToAbort()

end
