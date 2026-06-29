



#define LOCATOR_ICON_FX_PULSE_SLOW		0x00000001
#define LOCATOR_ICON_FX_ALPHA_SLOW		0x00000008
#define LOCATOR_ICON_FX_SHAKE_NARROW	0x00000040
#define LOCATOR_ICON_FX_STATIC			0x00000100	// This icon draws at a fixed location on the HUD.



#include <sdktools>

public void OnPluginStart()
{
	//RegConsoleCmd("sm_test", test);
	HookEvent("bomb_dropped", bomb_dropped);
}

public Action test(int client, int args)
{
	return Plugin_Handled;
}


public void bomb_dropped(Event event, const char[] name, bool dontBroadcast)
{

	int entindex = event.GetInt("entindex", -1); //FindEntityByClassname(-1, "weapon_c4");

	if(entindex == -1 || !IsValidEdict(entindex))
		return;

	Event instructor_server_hint_create = CreateEvent("instructor_server_hint_create", true);
	
	if(instructor_server_hint_create == null)
		return;


	int iFlags, m_iPulseOption, m_iAlphaOption, m_iShakeOption;
	bool m_bStatic;

	m_iPulseOption = m_iAlphaOption = 3;
	m_iShakeOption = 2;
	m_bStatic = false;


	//0 : "No Pulse"
	//1 : "Slow Pulse"
	//2 : "Fast Pulse"
	//3 : "Urgent Pulse"
	iFlags |= (m_iPulseOption == 0) ? 0 : (LOCATOR_ICON_FX_PULSE_SLOW << (m_iPulseOption - 1));

	//0 : "No Pulse"
	//1 : "Slow Pulse"
	//2 : "Fast Pulse"
	//3 : "Urgent Pulse"
	iFlags |= (m_iAlphaOption == 0) ? 0 : (LOCATOR_ICON_FX_ALPHA_SLOW << (m_iAlphaOption - 1));

	//0 : "No Shaking"
	//1 : "Narrow Shake"
	//2 : "Wide Shake"
	iFlags |= (m_iShakeOption == 0) ? 0 : (LOCATOR_ICON_FX_SHAKE_NARROW << (m_iShakeOption - 1));

	//0 : "Follow the Target Entity"
	//1 : "Show on the hud"
	iFlags |= m_bStatic ? LOCATOR_ICON_FX_STATIC : 0;




	//PrintToServer("instructor_server_hint_create");
	
	instructor_server_hint_create.SetString("hint_name", "target1");
	instructor_server_hint_create.SetString("hint_replace_key", "");
	instructor_server_hint_create.SetInt("hint_target", entindex);
	instructor_server_hint_create.SetInt("hint_activator_userid", event.GetInt("userid"));
	instructor_server_hint_create.SetInt("hint_timeout", 20);
	
	instructor_server_hint_create.SetString("hint_icon_onscreen", "icon_interact");
	instructor_server_hint_create.SetString("hint_icon_offscreen", "icon_interact");
	instructor_server_hint_create.SetString("hint_caption", "Take the bomb!");
	instructor_server_hint_create.SetString("hint_activator_caption", "Take the bomb noob!");
	instructor_server_hint_create.SetString("hint_color", "255,165,0");
	
	instructor_server_hint_create.SetFloat("hint_icon_offset", 20.0);
	instructor_server_hint_create.SetFloat("hint_range", 0.0);
	
	instructor_server_hint_create.SetInt("hint_flags", iFlags);
	
	instructor_server_hint_create.SetString("hint_binding", "");
	instructor_server_hint_create.SetString("hint_gamepad_binding", "");
	
	instructor_server_hint_create.SetBool("hint_allow_nodraw_target", true);

	//0 : "Show"
	//1 : "Don't show"
	instructor_server_hint_create.SetBool("hint_nooffscreen", false);

	instructor_server_hint_create.SetBool("hint_forcecaption", true);
	instructor_server_hint_create.SetBool("hint_local_player_only", false);
	

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) // dead players do not see message
			continue;

		instructor_server_hint_create.FireToClient(i);
	}


	
	delete instructor_server_hint_create;

}

/*
		event->SetString( "hint_name", GetEntityName().ToCStr() );
		event->SetString( "hint_replace_key", m_iszReplace_Key.ToCStr() );
		event->SetInt( "hint_target", pTargetEntity->entindex() );
		event->SetInt( "hint_activator_userid", ( pActivator ? pActivator->GetUserID() : 0 ) );
		event->SetInt( "hint_timeout", m_iTimeout );
		event->SetString( "hint_icon_onscreen", m_iszIcon_Onscreen.ToCStr() );
		event->SetString( "hint_icon_offscreen", m_iszIcon_Offscreen.ToCStr() );
		event->SetString( "hint_caption", m_iszCaption.ToCStr() );
		event->SetString( "hint_activator_caption", pActivatorCaption );
		event->SetString( "hint_color", szColorString );
		event->SetFloat( "hint_icon_offset", m_fIconOffset );
		event->SetFloat( "hint_range", m_fRange );
		event->SetInt( "hint_flags", iFlags );
		event->SetString( "hint_binding", m_iszBinding.ToCStr() );
		event->SetString( "hint_gamepad_binding", m_iszGamepadBinding.ToCStr() );
		event->SetBool( "hint_allow_nodraw_target", m_bAllowNoDrawTarget );
		event->SetBool( "hint_nooffscreen", m_bNoOffscreen );
		event->SetBool( "hint_forcecaption", m_bForceCaption );
		event->SetBool( "hint_local_player_only", bFilterByActivator );


		"icon_bulb" : "icon_bulb"
		"icon_caution" : "icon_caution"
		->"icon_alert" : "icon_alert"
		"icon_alert_red" : "icon_alert_red"
		"icon_tip" : "icon_tip"
		"icon_skull" : "icon_skull"
		"icon_no" : "icon_no"
		"icon_run" : "icon_run"
		->"icon_interact" : "icon_interact"
		"icon_button" : "icon_button"
		->"icon_door" : "icon_door"
		"icon_arrow_plain" : "icon_arrow_plain"
		"icon_arrow_plain_white_dn" : "icon_arrow_plain_white_dn"
		"icon_arrow_plain_white_up" : "icon_arrow_plain_white_up"
		"icon_arrow_up" : "icon_arrow_up"
		"icon_arrow_right" : "icon_arrow_right"
		->"icon_fire" : "icon_fire"
		"icon_present" : "icon_present"
		->"use_binding" : "show key bindings"
*/