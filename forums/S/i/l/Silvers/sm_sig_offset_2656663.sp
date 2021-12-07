/*
*	Gamedata Offset Tester
*	Copyright (C) 2021 Silvers and Dragokas
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION		"1.3.3"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] Gamedata Offset Tester
*	Author	:	SilverShot
*	Descrp	:	Dump memory bytes to server console for finding offsets. Uses signature bytes or gamedata for address.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=317074
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.3.3 (24-Feb-2021) Dragokas
	- Added ability to enter address in reverse order, e.g. sm_ptr "03 02 01 00" to access sm_ptr 0x010203.
	- Added ability to enter hex values in lowercase.

1.3.2 (16-Dec-2020) Dragokas
	- Added ability to (optionally) specify the number of bytes to be printed with sm_ptr (useful, when leftover is inaccessible and cause a crash).
	- Added ability to print < 10 bytes - for sm_ptr.
	- Added ability to display absolute address next to each line.
	- Appended ConVar "sm_sig_offset_display" with options: 2 and 3.
	- Added ConVar "sm_sig_offset_bytes" - How many bytes to print in total (by default).
	- Added ConVar "sm_sig_offset_style" - Offset numbering style: 10 - Decimal, 16 - Hexadecimal.
	- Code simplification.
	- Default value for "sm_sig_offset_print" ConVar is increased to 16 bytes per line.
	- "+ 0xX offset" prompt is printed in Hex now.

1.3.1 (21-Nov-2020) Dragokas
	- Added ability to input values (offset and bytes count) in hex format (should be prefixed with 0x) - e.g. sm_ptr 0xFFABCD
	- Fixed bug with incorrect generating gamedata where original gamedata contains CRLF style line breaks or extra whitespaces after "Games".
	- Fixed problem where gamedata files are precached by SM and cannot be re-used - now, random file name is created/deleted
	(for convenience, common sm_sig_offset.txt gamedata file is still been created, and NOT deleted).
	- If the count of bytes is not multiple by sm_sig_offset_print value, the leftover is also printed now.

1.3 (10-May-2020)
	- Increased gamedata buffer size to 100kb.
	- Various changes to tidy up code.

1.2 (01-Dec-2019)
	- Added command "sm_ptr" to print bytes from the specified memory address.

1.1.1 (28-June-2019)
	- Allowed negative offset lookup.

1.1 (26-June-2019)
	- Added convar "sm_sig_offset_library" to determine which library to search.

1.0 (25-June-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define GAMEDATA	"sm_sig_offset"

// #define MAX_BUFFER	51200	// left4downtown.l4d2.txt gamedata is ~41kb
#define MAX_BUFFER	1024000	// left4dhooks.l4d2.txt gamedata is ~92kb
#pragma dynamic MAX_BUFFER


ConVar gCvarDisplay, gCvarPrint, gCvarLibrary, gCvarBytes, gCvarStyle;



public Plugin myinfo =
{
	name = "[ANY] Gamedata Offset Tester",
	author = "SilverShot",
	description = "Dump memory bytes to server console for finding offsets. Uses signature bytes or gamedata for address.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=317074"
}

public void OnPluginStart()
{
	gCvarBytes =	CreateConVar(	"sm_sig_offset_bytes", 		"240",	"How many bytes to print in total (by default).", 0);
	gCvarDisplay =	CreateConVar(	"sm_sig_offset_display",	"3",	"0 = Dump all bytes space separated. 1 = Display offset number next to bytes. 2 = Display absolute address. 3 = 1+2.", 0);
	gCvarPrint =	CreateConVar(	"sm_sig_offset_print", 		"16",	"How many bytes to print per line in the console.", 0);
	gCvarStyle =	CreateConVar(	"sm_sig_offset_style", 		"16",	"Offset numbering style: 10 = Decimal, 16 = Hexadecimal.", 0);
	gCvarLibrary =	CreateConVar(	"sm_sig_offset_library", 	"1",	"Which library to search: 0 = Engine, 1 = Server.", 0);
	CreateConVar(					"sm_sig_offset_version",	PLUGIN_VERSION, "Gamedata Offset Tester plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"sm_sig_offset");

	RegAdminCmd("sm_sig_off",	CmdSig, ADMFLAG_ROOT, "Usage: sm_sig_off <offset> <signature bytes> || <gamedata> <signature> [offset] [bytes]");
	RegAdminCmd("sm_ptr",		CmdPtr, ADMFLAG_ROOT, "Prints 250 bytes from the specified memory address. Usage: sm_ptr <address> [offset] [bytes]");
}

public Action CmdPtr(int client, int args)
{
	if( args == 0 )
	{
		ReplyToCommand(client, "Usage: sm_ptr <address> [offset] [bytes]");
		return Plugin_Handled;
	}
	
	// Print
	char buff[16];
	int bytes;
	int offset;

	if( args >= 2 )
	{
		GetCmdArg(2, buff, sizeof(buff));
		offset = StringOffsetToInt(buff);
	}
	if( args >= 3 )
	{
		GetCmdArg(3, buff, sizeof(buff));
		bytes = StringOffsetToInt(buff);
	}
	else {
		bytes = gCvarBytes.IntValue;
	}

	GetCmdArg(1, buff, sizeof(buff));
	if( StrContains(buff, " ") != -1 ) // for sm_ptr "03 02 01 00" reversing bytes
	{
		TrimString(buff);
		ReplaceString(buff, sizeof(buff), "  ", " ");
		StrBytesReverse(buff, strlen(buff));
		Format(buff, sizeof(buff), "0x%s", buff);
	}
	Address pAddress = view_as<Address>(StringOffsetToInt(buff));

	PrintToServer("");
	PrintToServer("Displaying %d bytes from 0x%X + 0x%X offset.\n", bytes, pAddress, offset);

	PrintMemory(pAddress, offset, bytes);

	return Plugin_Handled;
}

public Action CmdSig(int client, int args)
{
	// Validate args
	if( args < 2 )
	{
		ReplyToCommand(client, "[SIG] Usage: sm_sig_off <offset> <signature bytes> || <gamedata> <signature> [offset] [bytes]");
		return Plugin_Handled;
	}

	// Vars
	Address pAddress;
	int offset;
	int bytes = gCvarBytes.IntValue;
	char temp[8];
	char sSignature[512];
	char sGamedata[PLATFORM_MAX_PATH];
	char sGamedataRandom[32];
	char sPath[PLATFORM_MAX_PATH];
	char sPathRandom[PLATFORM_MAX_PATH];

	// Get Args
	GetCmdArg(1, sGamedata, sizeof(sGamedata));
	GetCmdArg(2, sSignature, sizeof(sSignature));



	// Check for signature bytes version of command
	bool bSigScan = true;
	for( int i = 0; i < strlen(sGamedata); i++ )
	{
		if( IsCharNumeric(sGamedata[i]) == false && sGamedata[i] != '-' )
		{
			bSigScan = false;
			break;
		}
	}

	// Get Signature
	if( bSigScan == true )
	{
		// Vars
		offset = StringOffsetToInt(sGamedata);

		// Get signature
		GetCmdArgString(sSignature, sizeof(sSignature));

		int pos = FindCharInString(sSignature, ' ', false);
		Format(sSignature, sizeof(sSignature), sSignature[pos + 1]);

		// Strip quotes
		StripQuotes(sSignature);

		// Bytes wildcard
		ReplaceString(sSignature, sizeof(sSignature), "?", "2A");

		// Escape characters
		ReplaceString(sSignature, sizeof(sSignature), " ", "\\x");

		if( sSignature[0] != '@' ) // Linux
			Format(sSignature, sizeof(sSignature), "\\x%s", sSignature);
	}


	// Gamedata
	Handle hGameConfg;
	if( bSigScan == false )
	{
		// Optional args
		if( args == 3 )
		{
			GetCmdArg(3, temp, sizeof(temp));
			offset = StringOffsetToInt(temp);
		}
		if( args == 4 )
		{
			GetCmdArg(4, temp, sizeof(temp));
			bytes = StringOffsetToInt(temp);
		}

		// Gamedata exists
		BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", sGamedata);
		if( !FileExists(sPath) )
		{
			ReplyToCommand(client, "[SIG] Cannot find gamedata file: \"%s\".", sPath);
			return Plugin_Handled;
		}

		// Load gamedata
		hGameConfg = LoadGameConfigFile(sGamedata);
		if( hGameConfg == null )
		{
			ReplyToCommand(client, "[SIG] Cannot load gamedata: \"%s\".", sPath);
			return Plugin_Handled;
		}

		// Address
		pAddress = GameConfGetAddress(hGameConfg, sSignature);
		delete hGameConfg;
	}



	// Write temporary gamedata adding the "Address" section
	if( !pAddress )
	{
		File hFile;
		char buffer[MAX_BUFFER];

		if( bSigScan == false )
		{
			// Build gamedata path
			BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", sGamedata);
			if( !FileExists(sPath) )
			{
				ReplyToCommand(client, "[SIG] Cannot find gamedata (3): \"%s.txt\"", sGamedata);
				return Plugin_Handled;
			}

			// Read gamedata file
			hFile = OpenFile(sPath, "r", false);
			if( hFile == null )
			{
				ReplyToCommand(client, "[SIG] Cannot open file: \"%s\".", sPath);
				return Plugin_Handled;
			}

			// Load file
			int len = FileSize(sPath, false);
			hFile.ReadString(buffer, sizeof(buffer), len);
			delete hFile;
		}



		// Write custom gamedata
		BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
		
		// Using random file name to prevent sm precache problems
		FormatEx(sGamedataRandom, sizeof(sGamedataRandom), "%s-%i", GAMEDATA, GetRandomInt(0, 10000));
		BuildPath(Path_SM, sPathRandom, sizeof(sPathRandom), "gamedata/%s.txt", sGamedataRandom);
		
		hFile = OpenFile(sPathRandom, "w", false);

		int pos;
		if( bSigScan == false )
		{
			// Find entry section "Games"
			pos = StrContains(buffer, "\"Games\"") + 8;
			pos += StrContains(buffer[pos], "{");
			buffer[pos] = '\x0';

			// Write first part
			hFile.WriteLine(buffer, false);
		} else {
			hFile.WriteLine("\"Games\"");
		}

		// Write addresses section
		hFile.WriteLine("{");
		hFile.WriteLine("	\"#default\"");
		hFile.WriteLine("	{");
		hFile.WriteLine("		\"Addresses\"");
		hFile.WriteLine("		{");
		hFile.WriteLine("			\"%s\"", bSigScan ? "sig" : sSignature);
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"windows\"");
		hFile.WriteLine("				{");
		hFile.WriteLine("					\"signature\"	\"%s\"", bSigScan ? "sig" : sSignature);
		hFile.WriteLine("				}");
		hFile.WriteLine("				\"linux\"");
		hFile.WriteLine("				{");
		hFile.WriteLine("					\"signature\"	\"%s\"", bSigScan ? "sig" : sSignature);
		hFile.WriteLine("				}");
		hFile.WriteLine("			}");
		hFile.WriteLine("		}");

		if( bSigScan == true )
		{
			hFile.WriteLine("		\"Signatures\"");
			hFile.WriteLine("		{");
			hFile.WriteLine("			\"sig\"");
			hFile.WriteLine("			{");
			hFile.WriteLine("				\"library\"	\"%s\"", gCvarLibrary.IntValue ? "server" : "engine");
			hFile.WriteLine("				\"windows\"	\"%s\"", sSignature);
			hFile.WriteLine("				\"linux\"	\"%s\"", sSignature);
			hFile.WriteLine("			}");
			hFile.WriteLine("		}");
			hFile.WriteLine("	}");
			hFile.WriteLine("}");
		} else {
			// Write last part
			hFile.WriteLine("	}");
			hFile.WriteString(buffer[pos + 1], false);
		}
		FlushFile(hFile);
		delete hFile;
		
		// Backup our config
		CopyFile(sPathRandom, sPath);
		
		// Load new file
		hGameConfg = LoadGameConfigFile(sGamedataRandom);
		if( hGameConfg == null )
		{
			ReplyToCommand(client, "[SIG] Cannot find gamedata (4): \"%s\".", sPathRandom);
			
			// Remove random config file
			DeleteFile(sPathRandom);
			return Plugin_Handled;
		}
		
		// Get Address
		pAddress = GameConfGetAddress(hGameConfg, bSigScan ? "sig" : sSignature);

		// Clean up
		delete hGameConfg;
		
		// Remove random config file
		DeleteFile(sPathRandom);

		// Test again
		if( !pAddress )
		{
			ReplyToCommand(client, "[SIG] Cannot find signature.");
			return Plugin_Handled;
		}
	}


	// Print
	PrintToServer("");
	PrintToServer("Displaying %d bytes of %s from 0x%X + 0x%X offset.\n", bytes, bSigScan ? "sig" : sSignature, pAddress, offset);

	PrintMemory(pAddress, offset, bytes);
	
	return Plugin_Handled;
}

int StringOffsetToInt(char[] buff)
{
	int offset;
	if( strncmp(buff, "0x", 2, false) == 0 )
	{
		offset = HexToDec(buff[2]);
	}
	else {
		offset = StringToInt(buff);
	}
	return offset;
}

int HexToDec(char[] bytes)
{
	int len = strlen(bytes);
	int base = 1;
	int value = 0;

	for( int i = len - 1; i >= 0; i-- )
	{
		if( bytes[i] >= '0' && bytes[i] <= '9' )
		{
			value += (bytes[i] - 48) * base;
			base = base * 16;
		}
		else if( bytes[i] >= 'A' && bytes[i] <= 'F' )
		{
			value += (bytes[i] - 55) * base;
			base = base * 16;
		}
		else if( bytes[i] >= 'a' && bytes[i] <= 'f' )
		{
			value += (bytes[i] - 87) * base;
			base = base * 16;
		}
	}

	return value;
}

bool CopyFile(char[] SourceFile, char[] TargetFile)
{
	Handle hr = OpenFile(SourceFile, "rb", false);	
	if( hr )
	{
		Handle hw = OpenFile(TargetFile, "wb", false);	
		if( hw )
		{
			int bytesRead, buff[64];
			
			while( !IsEndOfFile(hr) )
			{
				bytesRead = ReadFile(hr, buff, sizeof(buff), 1);
				WriteFile(hw, buff, bytesRead, 1);
			}
			delete hw;
		}
		delete hr;
	}
}

void PrintMemory(Address pAddress, int offset, int bytes)
{
	// Loop memory
	char buff[128];
	int loop;
	for( int i = 0; i < bytes; i++ )
	{
		loop++;

		if( gCvarDisplay.IntValue == 0 )
		{
			// Load bytes into print buffer
			Format(buff, sizeof(buff), "%s%02X ", buff, LoadFromAddress(pAddress + view_as<Address>(offset) + view_as<Address>(i), NumberType_Int8));

			// Print line to console and reset buffer
			if( loop == gCvarPrint.IntValue )
			{
				PrintToServer(buff);

				buff[0] = '\x0';
				loop = 0;
			}
		} else {
			// Padded line offset numbers
			if( loop == 1 )
			{
				buff[0] = '\x0';
				
				if( gCvarDisplay.IntValue & 2 )
					Format(buff, sizeof(buff), "%8X ", view_as<int>(pAddress) + offset + i);
				
				if( gCvarDisplay.IntValue & 1 )
					Format(buff, sizeof(buff), gCvarStyle.IntValue == 10 ? "%s[%3d]  " : "%s[%3X]  ", buff, i + offset);
			}

			// Load bytes into print buffer
			Format(buff, sizeof(buff), "%s%02X ", buff, LoadFromAddress(pAddress + view_as<Address>(offset) + view_as<Address>(i), NumberType_Int8));

			// Double space in middle
			if( loop == gCvarPrint.IntValue / 2 ) StrCat(buff, sizeof(buff), " ");

			// Print line to console and reset buffer
			if( loop == gCvarPrint.IntValue )
			{
				PrintToServer(buff);

				buff[0] = '\x0';
				loop = 0;
			}
		}
	}
	// if unprinted bytes left
	if( buff[0] != '\x0' )
	{
		PrintToServer(buff);
	}
}

void StrBytesReverse(char[] buff, int len)
{
	int tmp;
	int last = len - 1;
	for( int i = 0; i < last / 2 - 1; i += 3 )
	{
		tmp = buff[i];
		buff[i] = buff[last - i - 1];
		buff[last - i - 1] = tmp;
		
		tmp = buff[i+1];
		buff[i+1] = buff[last - i];
		buff[last - i] = tmp;
	}
}