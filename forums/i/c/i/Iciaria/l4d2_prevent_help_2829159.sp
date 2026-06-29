#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_NAME       "[L4D2] Prevent Help"
#define PLUGIN_DESCRIPTION    "Prevent Survivor bot Help incap survivor when tank/witch alive."
#define PLUGIN_VERSION      "1.1"
#define PLUGIN_AUTHOR       "Iciaria/oblivcheck"
#define PLUGIN_URL        ""

#define WITCH 0
#define COUNT_FRAME 5
#define COUNT_CMD 10

ArrayList aWitchList;
ArrayList aTankList;
ArrayList aShouldBlockAreaList;
int counter[MAXPLAYERS+1];
bool allow;

public void OnPluginStart()
{
  HookEvent("witch_harasser_set", Event_Witch_Harasser_Set);
  HookEvent("tank_spawn", Event_Tank_Spawn);
  aWitchList = CreateArray(1);
  aTankList = CreateArray(1);
  aShouldBlockAreaList = CreateArray(2);
}

void Event_Witch_Harasser_Set(Event event, const char[] name, bool dontBroadcast)
{
  aWitchList.Push( event.GetInt("witchid") );
}

void Event_Tank_Spawn(Event event, const char[] name, bool dontBroadcast)
{
  aTankList.Push( event.GetInt("tankid") );
}


public void OnEntityDestroyed( int entity)
{
  int index = aWitchList.FindValue(entity);
  if(index != -1)
  {
    aWitchList.Erase(index);
    return;
  }

  index = aTankList.FindValue(entity)
  if(index != -1)
    aTankList.Erase(index);

  return;
}

public void OnClientPutInServer(int client)
{
  counter[client] = 0;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum)
{
  if( GetClientTeam(client) != 2 )
    return Plugin_Continue;

  if(!IsPlayerAlive(client) )
    allow = false;

  if(L4D_IsPlayerHangingFromLedge(client) || L4D_IsPlayerIncapacitated (client) )
  {
      float pos[3];
      GetClientAbsOrigin(client, pos);
      Address area =  L4D_GetNearestNavArea(pos);
      if(area == view_as<Address>(0) )
        PrintToServer("Cant Found NavArea(incap player: %N)", client);
      else
        aShouldBlockAreaList.Push(area);
  }
  else if(IsFakeClient(client) )
  {
    if(counter[client] == 0)
      counter[client] = cmdnum;

    if( (cmdnum - counter[client]) > COUNT_CMD)
    {
      float pos[3];
      GetClientAbsOrigin(client, pos);
      Address area =  L4D_GetNearestNavArea(pos);
      float speed[3];
      for(int i=0; i<3;i++)
        speed[i] = GetRandomFloat(50.0, 200.0); 
      if(aShouldBlockAreaList.FindValue(area) != -1 )
        TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speed)
      counter[client] = 0;
    }
  }

  int Length = aShouldBlockAreaList.Length;
  if(!Length)
    return Plugin_Continue;

  if( !IsFakeClient(client) )
      return Plugin_Continue;
#if WITCH
  if(aWitchList.Length || aTankList.Length)
#else
  if(aTankList.Length)
    allow = true;
#endif
  else allow = false;

  return Plugin_Continue;
}

int skip;
public void OnGameFrame()
{
  skip++;
  if(skip > COUNT_FRAME)
    skip = 0;
  else return;

  if(allow)
  {
    Address area;
    for(int i=0; i < aShouldBlockAreaList.Length; i++)
    {
      area = aShouldBlockAreaList.Get(i);
      int flags = L4D_GetNavArea_AttributeFlags(area);
      aShouldBlockAreaList.Set(i, flags, 1)
      L4D_SetNavArea_AttributeFlags(area, flags | NAV_BASE_PLAYERCLIP);
    }
    // If necessary, identify which survivor bot is closest to the 
    // 'Nav area that should not be blocked'; otherwise, 
    // simply prevent them from helping any incapacitated teammates 
    // until the Tank and Witch are dead.

    /*
    if(L4D_HasVisibleThreats(client) )
    {
      if(aDontBlockAreaList.Length)
        aShouldBlockAreaList = aDontBlockAreaList;
    }
    else
    {
      aDontBlockAreaList = aShouldBlockAreaList.clone;
      aDontBlockAreaList
    }
    */
  }
  else
  {
    Address area;
    for(int i=0; i < aShouldBlockAreaList.Length; i++)
    {
      area = aShouldBlockAreaList.Get(i);
      int flags = L4D_GetNavArea_AttributeFlags(area);
      L4D_SetNavArea_AttributeFlags(area, flags & ~NAV_BASE_PLAYERCLIP);
    }
 
    aShouldBlockAreaList.Clear(); 
  }
}
