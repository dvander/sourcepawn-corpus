public Plugin myinfo =
{
	name = "ProgressBarUnlocker",
	author = "Poggu",
	description = "Changes progressbar's duration 5 bit limit to 16 to allow more than 15 seconds of duration",
	version = "1.0.0"
};

Address g_pProgressBarDuration;
Address g_SendTableCRC;
bool g_isCRCInvalidated;
int g_oldCRCBytes;
int g_oldBytes;

// m_iProgressBarDuration is a signed 5 bit integer in the latest csgo version

public void OnPluginStart()
{
  // Enable sv_sendtables to allow players to join the server when server's SendTable is modified
  SetConVarInt(FindConVar("sv_sendtables"), 1);

  GameData hConfig = LoadGameConfigFile("ProgressBarUnlocker");
  Assert(!hConfig, "Failed to load ProgressBarUnlocker gamedata");

  Address g_progressBarDuration = hConfig.GetAddress("progressBarDuration");
  Assert(!g_progressBarDuration, "Failed to get progressBarDuration address");

  int g_platform = hConfig.GetOffset("WindowsOrLinux");
  Assert(!g_platform, "Failed to get platform offset");

  g_SendTableCRC = hConfig.GetAddress("g_SendTableCRC");
  g_isCRCInvalidated = !!g_SendTableCRC;

  if(g_isCRCInvalidated) // Invalidate CRC only if a) it wasn't done by another plugin b) gamedata is correct
  {
    //Invalidate CRC checksum, yoinked from hud limit unlocker
    g_oldCRCBytes = LoadFromAddress(g_SendTableCRC, NumberType_Int32);
    if(g_oldCRCBytes != 1337)
      g_isCRCInvalidated = false;
    else
      StoreToAddress(g_SendTableCRC, 1337, NumberType_Int32);
  }

  if(g_platform == 1)
  {
    // Get address from MOV instructions
    g_pProgressBarDuration = view_as<Address>(LoadFromAddress(g_progressBarDuration, NumberType_Int32));
    Assert(!g_pProgressBarDuration, "Failed to get g_pProgressBarDuration");
    g_oldBytes = LoadFromAddress(g_pProgressBarDuration, NumberType_Int32);
    StoreToAddress(g_pProgressBarDuration, 16, NumberType_Int32); // change from 5 bits to 16
  }
  else
  {
    // Get sendtable object from MOV instruction
    g_pProgressBarDuration = view_as<Address>(LoadFromAddress(g_progressBarDuration, NumberType_Int32)) + view_as<Address>(12);
    Assert(!g_pProgressBarDuration, "Failed to get g_pProgressBarDuration");
    g_oldBytes = LoadFromAddress(g_pProgressBarDuration, NumberType_Int32);
    StoreToAddress(g_pProgressBarDuration, 16, NumberType_Int8); // change from 5 bits to 16
  }
}

// Restore old bytes when plugin gets unloaded
public void OnPluginEnd()
{
  if(g_oldBytes && g_pProgressBarDuration)
    StoreToAddress(g_pProgressBarDuration, g_oldBytes, NumberType_Int32);

  if(g_isCRCInvalidated && g_oldCRCBytes)
    StoreToAddress(g_SendTableCRC, g_oldCRCBytes, NumberType_Int32);
}

void Assert(bool b, const char[] err)
{
  if(b)
    SetFailState(err);
}