float Angles[33][3];


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:ang[3], &weapon)
{
	if (buttons & IN_MOVERIGHT)
	{
		GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", Angles[client]);
		Angles[client][2] = !Angles[client][2] ? 5.0 : Angles[client][2]+ 1.0 ;
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", Angles[client]);
	}
	if (buttons & IN_MOVELEFT)
	{
		GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", Angles[client]);
		Angles[client][2] = !Angles[client][2] ? -5.0 : Angles[client][2] - 1.0 ;
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", Angles[client]);
	}
	return Plugin_Continue;
}
