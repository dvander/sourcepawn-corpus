public Plugin:myinfo =
{
	name = "Disable HUD money",
	author = "Pheonix (˙·٠●Феникс●٠·˙)",
	version = "1.0",
	url = "http://www.hlmod.ru/ http://zizt.ru/"
};

new Handle:mp_maxmoney, bool:u[MAXPLAYERS+1], String:m[10];

public OnPluginStart() 
{
	mp_maxmoney = FindConVar("mp_maxmoney");
	GetConVarString(mp_maxmoney, m, 10);
}

public OnClientPutInServer(iClient)  if(!IsFakeClient(iClient)) 
{
	SendConVarValue(iClient, mp_maxmoney, "0");
	u[iClient] = false;
}

public Action:OnPlayerRunCmd(iClient, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_SCORE) 
	{
		if(!u[iClient])
		{
			u[iClient] = true;
			SendConVarValue(iClient, mp_maxmoney, m);
		}
	}
	else if(u[iClient])
	{
		u[iClient] = false;
		SendConVarValue(iClient, mp_maxmoney, "0");
	}
	return Plugin_Continue;
}