new Handle:cvar_master_switch

public OnPluginStart()
{
  cvar_master_switch = CreateConVar("sm_master_switch", "0")
  HookConVarChange(cvar_master_switch, CVAR_Changed)

  RegAdminCmd("switch_toggle", Command_switch_toggle, ADMFLAG_CONVARS)
}


public CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{ 
  ToggleConVars(GetConVarInt(cvar_master_switch))
}


new g_toggle_state = 0
public Action:Command_switch_toggle(client, args)
{
  if (g_toggle_state == 0)
  {
    g_toggle_state = 1
    ReplyToCommand(client, "Switching on")
  }
  else
  {
    g_toggle_state = 0
    ReplyToCommand(client, "Switching off")
  }
  ToggleConVars(g_toggle_state)
  return Plugin_Handled
}


public ToggleConVars(toggle)
{
  new Handle:temp_cvar
  if (toggle == 1)
  {
    temp_cvar = FindConVar("z_witch_blah")
    SetConVarInt(temp_cvar, 1)

    temp_cvar = FindConVar("z_blah_blah")
    SetConVarInt(temp_cvar, 0)
    
    temp_cvar = FindConVar("z_blah_blah")
    SetConVarInt(temp_cvar, 600)
  }
  else
  {
    temp_cvar = FindConVar("z_witch_blah")
    SetConVarInt(temp_cvar, 0)

    temp_cvar = FindConVar("z_blah_blah")
    SetConVarInt(temp_cvar, 1000)
    
    temp_cvar = FindConVar("z_blah_blah")
    SetConVarInt(temp_cvar, 0)
  }
}


