new clientMaxHealth[MAXPLAYERS];

public OnPluginStart()
{
	m_flMaxspeed = FindSendPropInfo("CTFPlayer", "m_flMaxspeed");
}

public Action:event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, setMaxHealth, client);
}

public Action:setMaxHealth(Handle:timer, any:client)
{
	if(client < 1)
		return Plugin_Stop;
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(class == TFClass_Unknown)
		return Plugin_Stop;
	
	clientMaxHealth[client] = GetClientHealth(client);
	
	return Plugin_Stop;
}

public Float:GetClientBaseSpeed(client)
{
	new Float:speed;
	new TFClassType:class = TF2_GetPlayerClass(client);
	new cond = GetEntData(client, m_nPlayerCond);
	
	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new String:classname[64];
	GetEdictClassname(iWeapon, classname, 64);

	new itemDefinition = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	
	switch(class)
	{
		case TFClass_Soldier:
		{
			speed = 240.0;
			
			//The Equalizer
			//the speed of the wielding Soldier is also inversely proportional to his health
			if(itemDefinition == 128)
			{
				new Float: healthPercentage = float(GetClientHealth(client)) / float(clientMaxHealth[client]);
				
				if(healthPercentage >= 0.80)
				{
					speed *= 1.0;
				}else if(healthPercentage >= 0.60)
				{
					speed *= 1.08;
				}else if(healthPercentage >= 0.40)
				{
					speed *= 1.16;
				}else if(healthPercentage >= 0.20)
				{
					speed *= 1.32;
				}else{
					speed *= 1.48;
				}
			}
		}
	
	return speed;
}

stock ResetClientSpeed(client)
{
	if(IsValidEntity(iWeapon)) 
	{
		SetEntDataFloat(client, m_flMaxspeed, GetClientBaseSpeed(client));
	}
}