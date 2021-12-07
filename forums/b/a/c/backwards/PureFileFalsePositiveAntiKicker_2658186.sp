#include <sourcemod>

public Plugin:myinfo =
{
	name = "Pure File False Positive Anti Kicker",
	author = "backwards",
	description = "Prevents clients from being kicked for false positives against the sv_pure system.",
	version = SOURCEMOD_VERSION,
	url = "http://www.steamcommunity.com/id/mypassword"
}

new Windows_Orginal_Bytes[6] = {0xFF, 0x87, 0xE8, 0x46, 0x00, 0x00};
new Linux_Orginal_Bytes[3] = {0x83, 0xC0, 0x01};

enum e_OS
{
	Unknown = 0,
	Windows,
	Linux
}

new Address:ProcessPureFileAddy;
new OS;

public OnPluginStart()
{
	if (GetEngineVersion() == Engine_CSGO)
	{
		ProcessPureFileAddy = GameConfGetAddress(LoadGameConfigFile("PureFilePatch"), "ProcessPureFile");
		LogMessage("ProcessPureFile Address = 0x%X!", ProcessPureFileAddy);
	
		OS = LoadFromAddress(ProcessPureFileAddy + Address:1, NumberType_Int8);
		switch(OS)
		{
			case 0xB9: //Linux
			{
				OS = Linux;
				
				for(int i = 0;i < 3;i++)
					StoreToAddress(ProcessPureFileAddy + Address:0x318 + view_as<Address>(i), 0x90, NumberType_Int8);
			}
			case 0x8B: //Windows
			{
				OS = Windows;
				
				for(int i = 0;i < 6;i++)
					StoreToAddress(ProcessPureFileAddy + Address:0x12D + view_as<Address>(i), 0x90, NumberType_Int8);
			}
			default:
			{
				OS = Unknown;
				SetFailState("ProcessPureFile Signature Incorrect. (0x%x)", OS);
			}
		}
	}
	else
		SetFailState("GameMode Not Supported (%s)", GetEngineVersion());
}

public OnPluginEnd()
{
	if (GetEngineVersion() == Engine_CSGO)
	{
		switch(OS)
		{
			case Linux:
			{
				for(int i = 0;i < 3;i++)
					StoreToAddress(ProcessPureFileAddy + Address:0x318 + view_as<Address>(i), Linux_Orginal_Bytes[i], NumberType_Int8);
			}
			case Windows:
			{
				for(int i = 0;i < 6;i++)
					StoreToAddress(ProcessPureFileAddy + Address:0x12D + view_as<Address>(i), Windows_Orginal_Bytes[i], NumberType_Int8);
			}
		}
	}
	else
		SetFailState("GameMode Not Supported (%s)", GetEngineVersion());
}