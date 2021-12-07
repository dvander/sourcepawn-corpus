#pragma semicolon 1

#include <sourcemod>
#include <socket>

new Handle:g_PasswordCVar = INVALID_HANDLE;
new Handle:g_HostCVar = INVALID_HANDLE;
new Handle:g_PortCVar = INVALID_HANDLE;
new g_NextPacketID = 1;

#define PACKET_MAX_SIZE 4096

#define STATE_AUTHING 0
#define STATE_COMMANDEXEC 1

public Plugin:myinfo = {
	name        = "More RCON",
	author      = "PimpinJuice",
	description = "Send RCON commands to other servers.",
	version     = "1.0.0",
	url         = "https://forums.alliedmods.net/showthread.php?p=1974076"
};

public OnPluginStart() {
	g_PasswordCVar = CreateConVar("sm_morercon_password", "", "Remote server RCON password");
	g_HostCVar = CreateConVar("sm_morercon_host", "0.0.0.0", "Remote server host");
	g_PortCVar = CreateConVar("sm_morercon_port", "27015", "Remote server port");

	RegAdminCmd("sm_morercon", MoreRCONCallback, ADMFLAG_RCON, "Execute a remote command");
}

stock ProduceLittleEndian(any:value, String:output[]) {
	output[0] = ((value << 24) >> 24) & 0x000000FF;
	output[1] = ((value << 16) >> 24) & 0x000000FF;
	output[2] = ((value << 8) >> 24) & 0x000000FF;
	output[3] = (value >> 24) & 0x000000FF;
}

GetNextPacketID() {
	new id = g_NextPacketID;
	g_NextPacketID++;

	return id;
}

public MoreRCONSocketConnected(Handle:p_Socket, any:p_RequestParam) {
	new String:s_Packet[PACKET_MAX_SIZE];

	decl String:s_Password[256];
	GetArrayString(p_RequestParam, 1, s_Password, sizeof(s_Password));

	new s_PacketID = GetNextPacketID(); // This can be any int above zero, doesn't have to be unique
	new s_PacketSize = 10 + strlen(s_Password);
	new s_PacketAuthID = 3;

	ProduceLittleEndian(s_PacketSize, s_Packet);
	ProduceLittleEndian(s_PacketID, s_Packet[4]);
	ProduceLittleEndian(s_PacketAuthID, s_Packet[8]);

	for(new s_Index = 0; s_Index < strlen(s_Password); s_Index++) {
		s_Packet[12 + s_Index] = s_Password[s_Index];
	}

	s_Packet[12 + strlen(s_Password)] = '\0';
	s_Packet[13 + strlen(s_Password)] = '\0';
	
	SocketSend(p_Socket, s_Packet, s_PacketSize + 4);
}

stock ExpandCellsToString(const any:p_Arr[], p_Size, String:p_Output[]) {
	for(new s_Index = 0; s_Index < p_Size; s_Index++) {
		p_Output[s_Index] = p_Arr[s_Index] & 0x000000FF;
	}
}

stock PackStringToCells(const String:p_Str[], p_Size, any:p_Output[]) {
	for(new s_Index = 0; s_Index < p_Size; s_Index++) {
		p_Output[s_Index] = p_Str[s_Index] & 0x000000FF;
	}
}

stock any:LittleEndianToValue(String:p_LittleEndian[]) {
	return (p_LittleEndian[0] & 0x000000FF) |
		((p_LittleEndian[1] << 8) & 0x0000FF00) |
		((p_LittleEndian[2] << 16) & 0x00FF0000) |
		((p_LittleEndian[3] << 24) & 0xFF000000);
}

SendRCONCommand(Handle:p_Socket, Handle:p_RequestParam) {
	decl String:s_Command[PACKET_MAX_SIZE];
	GetArrayString(p_RequestParam, 0, s_Command, sizeof(s_Command));

	SetArrayCell(p_RequestParam, 2, 0);
	SetArrayArray(p_RequestParam, 3, {0}, 1);
	SetArrayCell(p_RequestParam, 4, STATE_COMMANDEXEC);

	new s_PacketID = GetNextPacketID(); // This can be any int above zero, doesn't have to be unique
	new s_PacketSize = 10 + strlen(s_Command);
	new s_PacketExecID = 2;

	new String:s_Packet[PACKET_MAX_SIZE];

	ProduceLittleEndian(s_PacketSize, s_Packet);
	ProduceLittleEndian(s_PacketID, s_Packet[4]);
	ProduceLittleEndian(s_PacketExecID, s_Packet[8]);

	for(new s_Index = 0; s_Index < strlen(s_Command); s_Index++) {
		s_Packet[12 + s_Index] = s_Command[s_Index];
	}

	s_Packet[12 + strlen(s_Command)] = '\0';
	s_Packet[13 + strlen(s_Command)] = '\0';

	SocketSend(p_Socket, s_Packet, s_PacketSize + 4);
}

public MoreRCONSocketReceive(Handle:p_Socket, String:p_Data[], const p_DataSize, any:p_RequestParam) {
	decl s_DataCells[p_DataSize];
	PackStringToCells(p_Data, p_DataSize, s_DataCells);

	new s_ReceivedBytes = GetArrayCell(p_RequestParam, 2);

	if(s_ReceivedBytes == 0) {
		SetArrayCell(p_RequestParam, 2, p_DataSize);
		SetArrayArray(p_RequestParam, 3, s_DataCells, p_DataSize);
	}
	else {
		decl s_ReceivedCells[s_ReceivedBytes + p_DataSize];
		GetArrayArray(p_RequestParam, 3, s_ReceivedCells, s_ReceivedBytes);

		for(new s_Index = 0; s_Index < p_DataSize; s_Index++) {
			s_ReceivedCells[s_ReceivedBytes + s_Index] = p_Data[s_Index] & 0x000000FF;
		}

		SetArrayCell(p_RequestParam, 2, s_ReceivedBytes + p_DataSize);
		SetArrayArray(p_RequestParam, 3, s_ReceivedCells, s_ReceivedBytes + p_DataSize);
	}

	new s_TotalReceivedBytes = GetArrayCell(p_RequestParam, 2);

	if(s_TotalReceivedBytes < 12) {
		return;
	}

	decl s_ReceivedData[s_TotalReceivedBytes];
	GetArrayArray(p_RequestParam, 3, s_ReceivedData, s_TotalReceivedBytes);

	decl String:s_ReceivedStr[s_TotalReceivedBytes];
	ExpandCellsToString(s_ReceivedData, s_TotalReceivedBytes, s_ReceivedStr);

	new s_ExpectedSize = LittleEndianToValue(s_ReceivedStr);

	if(s_TotalReceivedBytes < s_ExpectedSize) {
		return;
	}

	new s_ID = LittleEndianToValue(s_ReceivedStr[4]);
	new s_Type = LittleEndianToValue(s_ReceivedStr[8]);

	new s_StrLen = s_ExpectedSize - 10;
	decl String:s_Str[s_StrLen + 1];

	for(new s_Index = 0; s_Index < s_StrLen; s_Index++) {
		s_Str[s_Index] = s_ReceivedStr[12 + s_Index];
	}

	s_Str[s_StrLen] = '\0';

	new s_State = GetArrayCell(p_RequestParam, 4);

	if(s_State == STATE_AUTHING) {
		// We might get a bogus packet first (if type == 0)
		if(s_Type == 0) {
			// We need to read another packet. It's the actual response.
			// First ensure that we have enough bytes to merit operating
			new s_MinimumSizeWithExtraPacket = s_ExpectedSize + 16;

			if(s_TotalReceivedBytes < s_MinimumSizeWithExtraPacket) {
				return;
			}

			new s_SecondExpectedSize = LittleEndianToValue(s_ReceivedStr[s_ExpectedSize + 4]);

			if(s_TotalReceivedBytes < (s_ExpectedSize + 4 + s_SecondExpectedSize + 4)) {
				return;
			}

			new s_SecondID = LittleEndianToValue(s_ReceivedStr[s_ExpectedSize + 8]);
			new s_SecondType = LittleEndianToValue(s_ReceivedStr[s_ExpectedSize + 12]);

			if(s_SecondType != 2) {
				PrintToServer("ERROR: Expected auth packet after bogus packet, but didn't find it. (%d != 2)", s_SecondType);
				return;
			}

			if(s_SecondID == -1) {
				PrintToServer("Invalid RCON password");
				return;
			}

			SendRCONCommand(p_Socket, p_RequestParam);
			return;
		}

		if(s_ID == -1) {
			PrintToServer("Invalid RCON password");
			return;
		}

		SendRCONCommand(p_Socket, p_RequestParam);
		return;
	}
	else if(s_State == STATE_COMMANDEXEC) {
		new s_Client = GetArrayCell(p_RequestParam, 5);
		TrimString(s_Str);

		if(s_Client == 0) {
			PrintToServer("%s", s_Str);
		}
		else {
			PrintToConsole(s_Client, "%s", s_Str);
		}
		
		CloseHandle(p_Socket);

		ClearArray(p_RequestParam);
		CloseHandle(p_RequestParam);
	}
}

public MoreRCONSocketDisconnected(Handle:p_Socket, any:p_RequestParam) {
	CloseHandle(p_Socket);
	ClearArray(p_RequestParam);
	CloseHandle(p_RequestParam);
}

public MoreRCONSocketError(Handle:p_Socket, const errorType, const errorNum, any:p_RequestParam) {
	CloseHandle(p_Socket);
	ClearArray(p_RequestParam);
	CloseHandle(p_RequestParam);
}


public Action:MoreRCONCallback(client, args) {
	// Read entire command string into a buffer
	new String:s_Buffer[PACKET_MAX_SIZE];
	GetCmdArgString(s_Buffer, sizeof(s_Buffer));

	// Read our convars
	new s_Port = GetConVarInt(g_PortCVar);

	decl String:s_Host[256];
	GetConVarString(g_HostCVar, s_Host, sizeof(s_Host));

	decl String:s_Password[256];
	GetConVarString(g_PasswordCVar, s_Password, sizeof(s_Password));	

	// Create an ADT for the request information
	new Handle:s_RequestParam = CreateArray(PACKET_MAX_SIZE);

	PushArrayString(s_RequestParam, s_Buffer);
	PushArrayString(s_RequestParam, s_Password);
	PushArrayCell(s_RequestParam, 0); // Response buffer recieved length
	PushArrayArray(s_RequestParam, {0}, 1); // Response buffer
	PushArrayCell(s_RequestParam, STATE_AUTHING); // Used for state
	PushArrayCell(s_RequestParam, client);

	// Setup our socket connection
	new Handle:s_Socket = SocketCreate(SOCKET_TCP, MoreRCONSocketError);
	SocketSetArg(s_Socket, s_RequestParam);
	SocketConnect(s_Socket, MoreRCONSocketConnected, MoreRCONSocketReceive, MoreRCONSocketDisconnected, s_Host, s_Port);

	return Plugin_Handled;
}