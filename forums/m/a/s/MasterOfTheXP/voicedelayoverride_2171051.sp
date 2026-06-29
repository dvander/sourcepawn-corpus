public OnPluginStart()
{
	AddCommandListener(Listener_voicemenu, "voicemenu");
}

new Handle:cvarVoiceDelay;

public OnConfigsExecuted()
{
	cvarVoiceDelay = FindConVar("tf_max_voice_speak_delay");
}

public Action:Listener_voicemenu(client, const String:command[], args)
{
	if (CheckCommandAccess(client, "voicedelay", ADMFLAG_RESERVATION))
		SetConVarFloat(cvarVoiceDelay, -9.9);
	else
		SetConVarFloat(cvarVoiceDelay, 1.5);
}