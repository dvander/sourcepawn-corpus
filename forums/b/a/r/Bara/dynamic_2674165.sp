/**
 * =============================================================================
 * Dynamic for SourceMod (C)2016 Matthew J Dunn.   All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */
#define dynamic_use_local_methodmap 1
#include <dynamic>
#include <regex>
#undef INVALID_DYNAMIC_OBJECT
#define INVALID_DYNAMIC_OBJECT			view_as<DynamicObject>(-1)
#pragma newdecls required
#pragma semicolon 1

// Public data
int s_CollectionSize = 0;
Handle s_FreeIndicies = null;
StringMap s_tObjectNames = null;
Handle g_sRegex_Vector = null;
int g_iDynamic_MemberLookup_Offset;
ArrayList g_aPlugins = null;

// Dynamics internal methodmaps
#include "dynamic/system/methodmaps/dynamicobject.sp"

// Dynamic datatypes
#include "dynamic/system/datatypes/bool.sp"
#include "dynamic/system/datatypes/dynamic.sp"
#include "dynamic/system/datatypes/float.sp"
#include "dynamic/system/datatypes/handle.sp"
#include "dynamic/system/datatypes/int.sp"
#include "dynamic/system/datatypes/string.sp"
#include "dynamic/system/datatypes/vector.sp"
#include "dynamic/system/datatypes/function.sp"

// Other features
#include "dynamic/system/commands.sp"
#include "dynamic/system/flatconfigs.sp"
#include "dynamic/system/handleusage.sp"
#include "dynamic/system/hooks.sp"
#include "dynamic/system/keyvalues.sp"
#include "dynamic/system/natives.sp"
#include "dynamic/system/plugins.sp"
#include "dynamic/system/selftest.sp"

public Plugin myinfo =
{
	name = "Dynamic",
	author = "Neuro Toxin",
	description = "Shared Dynamic Objects for Sourcepawn",
	version = "0.0.32",
	url = "https://forums.alliedmods.net/showthread.php?t=270519"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Initialise static plugin data
	s_Collection = CreateArray(Dynamic_Field_Count);
	s_CollectionSize = 0;
	s_FreeIndicies = CreateStack();
	s_tObjectNames = new StringMap();
	g_iDynamic_MemberLookup_Offset = ByteCountToCells(DYNAMIC_MEMBERNAME_MAXLEN)+1;
	g_aPlugins = CreateArray(2);
	
	// Reserve first object index for global settings
	DynamicObject settings = DynamicObject();
	settings.Initialise(null);
	
	// Ensure settings is assigned index 0
	if (view_as<int>(settings) != 0)
		SetFailState("Serious error encountered assigning server settings index!");
	
	// Reserve first object indicies for player objects
	for (int client = 1; client < MAXPLAYERS; client++)
	{
		settings = DynamicObject();
		settings.Initialise(null);
		
		// This is a check to ensure the index matches the client
		if (view_as<int>(settings) != client)
			SetFailState("Serious error encountered assigning player settings indicies!");
	}
	
	// Create natives
	CreateNatives();
	
	// Register commands
	RegisterCommands();
	
	// Register library
	RegPluginLibrary("dynamic");
	return APLRes_Success;
}

public void OnLibraryRemoved(const char[] name)
{
	_Dynamic_CollectGarbage();
}

public void OnPluginEnd()
{
	// Dispose of all objects in the collection pool
	while (s_CollectionSize > 0)
	{
		_Dynamic_Dispose(view_as<DynamicObject>(s_CollectionSize - 1), false, _, _, false);
	}
}

public void OnMapStart()
{
	_Dynamic_CollectGarbage();
}

stock void OnClientDisconnect_Post(int client)
{
	_Dynamic_ResetObject(client);
}

stock int _Dynamic_Initialise(Handle plugin, int blocksize=64, int startsize=0, bool persistent=false)
{
	int index = -1;
	DynamicObject member;
	
	// Always try to reuse a previously disposed index
	while (PopStackCell(s_FreeIndicies, index))
	{
		if (index < s_CollectionSize)
		{
			member = view_as<DynamicObject>(index);
			break;
		}
		index = -1;
	}
	
	// Create a new index if required
	if (index == -1)
		member = DynamicObject();
	
	// Initial 
	member.Initialise(plugin, blocksize, startsize, persistent);
	
	// Return the index
	return member.Index;
}

stock bool _Dynamic_Dispose(DynamicObject dynamic, bool disposemembers, bool reuse=false, int startsize=0, bool fromnative=true)
{
	if (!_Dynamic_IsValid(dynamic.Index, false, fromnative))
		return false;
	
	int blocksize = dynamic.BlockSize;
	
	// Dispose of child members if disposemembers is set
	if (disposemembers)
	{
		ArrayList data = dynamic.Data;
		int count = dynamic.MemberCount;
		DynamicOffset offset;
		DynamicObject disposableobject;
		Handle disposablehandle;
		
		Dynamic_MemberType membertype;
		
		for (int i = 0; i < count; i++)
		{
			offset = _Dynamic_GetMemberOffsetByIndex(dynamic, i);
			membertype = _Dynamic_GetMemberDataType(data, offset.Index, offset.Cell, blocksize);
			
			if (membertype == DynamicType_Dynamic)
			{
				disposableobject = view_as<DynamicObject>(_Dynamic_GetMemberDataInt(data, offset.Index, offset.Cell, blocksize));
				if (!disposableobject.IsValid(false))
					continue;
					
				// Check if member hasnt been referenced to another object
				if (disposableobject.Parent == dynamic)
					_Dynamic_Dispose(disposableobject, true);
			}
			else if (membertype == DynamicType_Handle)
			{
				disposablehandle = view_as<Handle>(_Dynamic_GetMemberDataInt(data, offset.Index, offset.Cell, blocksize));
				_Dynamic_SetMemberDataInt(data, offset.Index, offset.Cell, blocksize, 0);
				CloseHandle(disposablehandle);
			}
		}
	}
	
	// Close dynamic object array handles
	dynamic.Dispose(reuse);
	
	if (reuse)
	{
		// Reset the dynamic object so it can be used straight
		dynamic.Reset();
		return true;
	}
	
	// Remove all indicies from the end of the array which are empty (trimend array)
	int index = dynamic.Index;
	if (index + 1 == s_CollectionSize)
	{
		RemoveFromArray(s_Collection, index);
		s_CollectionSize--;
		
		for (int i = index - 1; i >= 0; i--)
		{
			if (s_Collection.Get(i, Dynamic_Index) != Invalid_Dynamic_Object)
				break;
			
			RemoveFromArray(s_Collection, i);
			s_CollectionSize--;
		}
	}
	else
	{
		// Mark the index as diposed and report the free index for reusage
		PushStackCell(s_FreeIndicies, dynamic);
	}
	return true;
}

stock void _Dynamic_CollectGarbage()
{
	// Dispose all objects owned by terminated plugins
	DynamicObject dynamic;
	for (int i = MAXPLAYERS; i < s_CollectionSize; i++)
	{
		dynamic = view_as<DynamicObject>(i);
		
		// Skip disposed objects
		if (!dynamic.IsValid(false))
			continue;
			
		// Skip persistent objects
		if (dynamic.Persistent)
			continue;
			
		// Validate owner plugin is still loaded
		if (!_Dynamic_Plugins_IsLoaded(dynamic.OwnerPlugin))
		{
			dynamic.Dispose(false);
			continue;
		}
			
		switch(GetPluginStatus(dynamic.OwnerPluginHandle))
		{
			case Plugin_Error, Plugin_Failed:
			{
				dynamic.Dispose(false);
			}
		}
	}
}

stock bool _Dynamic_ResetObject(DynamicObject dynamic, bool disposemembers, int blocksize=0, int startsize=0)
{
	if (!dynamic.IsValid(true))
		return false;
	
	if (blocksize == 0)
		blocksize = dynamic.BlockSize;
	
	return _Dynamic_Dispose(dynamic, disposemembers, true, startsize);
}

stock Handle _Dynamic_GetOwnerPlugin(DynamicObject dynamic)
{
	if (!dynamic.IsValid(true))
		return null;
	
	return dynamic.OwnerPluginHandle;
}

stock bool _Dynamic_SetName(DynamicObject dynamic, const char[] objectname, bool replace)
{
	if (!dynamic.IsValid(true))
		return false;
	
	return s_tObjectNames.SetValue(objectname, dynamic, replace);
}

stock DynamicObject _Dynamic_FindByName(const char[] objectname)
{
	// Find name in object names trie
	DynamicObject dynamic;
	if (!s_tObjectNames.GetValue(objectname, dynamic))
		return INVALID_DYNAMIC_OBJECT;
	
	// Check object is still valid
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OBJECT;
	
	// Return object index
	return dynamic;
}

stock DynamicObject _Dynamic_GetParent(DynamicObject dynamic)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OBJECT;
	
	return dynamic.Parent;
}

stock bool _Dynamic_GetName(DynamicObject dynamic, char[] buffer, int length)
{
	if (!dynamic.IsValid(true))
		return false;

	DynamicObject parent = dynamic.Parent;
	if (!parent.IsValid(false))
		return false;
	
	DynamicOffset offset = dynamic.ParentOffset;
	if (offset == INVALID_DYNAMIC_OFFSET)
		return false;
		
	_Dynamic_GetMemberNameByOffset(parent, offset, buffer, length);
	return true;	
}

stock bool _Dynamic_GetPersistence(DynamicObject dynamic)
{
	if (!dynamic.IsValid(true))
		return false;
		
	return dynamic.Persistent;
}

stock bool _Dynamic_SetPersistence(DynamicObject dynamic, bool value)
{
	if (!dynamic.IsValid(true))
		return false;
		
	dynamic.Persistent = value;
	return true;
}

stock bool _Dynamic_IsValid(int index, bool throwerror=false, bool fromnative=true)
{	
	// Check if object index is valid
	if (index < 0 || index >= s_CollectionSize)
	{
		if (throwerror)
		{
			if (fromnative)
				ThrowNativeError(SP_ERROR_NATIVE, "Unable to access dynamic handle %d", index);
			else
				ThrowError("Unable to access dynamic handle %d", index);
		}
		return false;
	}
		
	if (s_Collection.Get(index, Dynamic_Index) == -1)
	{
		if (throwerror)
		{
			if (fromnative)
				ThrowNativeError(SP_ERROR_NATIVE, "Tried to access disposed dynamic handle %d", index);
			else
				ThrowError("Tried to access disposed dynamic handle %d", index);
		}
		return false;
	}
	
	return true;
}

stock DynamicOffset _Dynamic_GetMemberOffset(DynamicObject dynamic, const char[] membername)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	// Find and return offset for member
	StringMap offsets = dynamic.Offsets;
	DynamicOffset offset;
	if (GetTrieValue(offsets, membername, offset))
		return offset;
	
	// No offset found
	return INVALID_DYNAMIC_OFFSET;
}

stock bool _Dynamic_GetMemberDataOffset(DynamicObject dynamic, const char[] membername, bool create, DynamicOffset &offset, Dynamic_MemberType type, int stringlength=0)
{
	// Find and return member offset
	if (dynamic.Offsets.GetValue(membername, offset))
		return true;
	
	// Return false if offset was not found
	if (!create)
		return false;
	
	// We need to create a new member
	_Dynamic_CreateMemberOffset(dynamic, offset, membername, type, stringlength);
	return true;
}

stock int _Dynamic_CreateMemberOffset(DynamicObject dynamic, DynamicOffset &offset, const char[] membername, Dynamic_MemberType type, int stringlength=0, StringMap offsets=null)
{
	int memberindex;
	ArrayList membernames = dynamic.MemberNames;
	
	// Increment member count
	dynamic.MemberCount++;
	
	// Get offsets if required
	if (offsets == null)
		offsets = dynamic.Offsets;
	
	offset = dynamic.NextOffset;
	offsets.SetValue(membername, offset);
	memberindex = membernames.PushString(membername);
	membernames.Set(memberindex, offset, g_iDynamic_MemberLookup_Offset);
	ArrayList data = dynamic.Data;
	int blocksize = dynamic.BlockSize;
	
	if (type == DynamicType_String)
	{
		if (stringlength == 0)
		{
			ThrowNativeError(SP_ERROR_NATIVE, "You must set a strings length when you initialise it");
			return false;
		}
		
		_Dynamic_ExpandIfRequired(data, offset, blocksize, ByteCountToCells(stringlength));
		_Dynamic_SetMemberDataType(data, offset, blocksize, type);
		_Dynamic_SetMemberStringLength(data, offset, blocksize, stringlength);
		dynamic.NextOffset = offset.Clone(blocksize, 3 + ByteCountToCells(stringlength));
		return memberindex;
	}
	else if (type == DynamicType_Vector)
	{
		_Dynamic_ExpandIfRequired(data, offset, blocksize, 3);
		_Dynamic_SetMemberDataType(data, offset, blocksize, type);
		dynamic.NextOffset = offset.Clone(blocksize, 4);
		return memberindex;
	}
	else
	{
		_Dynamic_ExpandIfRequired(data, offset, blocksize, 1);
		_Dynamic_SetMemberDataType(data, offset, blocksize, type);
		dynamic.NextOffset = offset.Clone(blocksize, 2);
		return memberindex;
	}
}

stock bool _Dynamic_RecalculateOffset(int &position, int &offset, int blocksize, bool aschar=false)
{
	// Calculate offset into internal array index and cell position
	if (aschar)
		blocksize *= 4;
		
	while (offset < 0)
	{
		offset+=blocksize;
		position--;
	}
	while (offset >= blocksize)
	{
		offset-=blocksize;
		position++;
	}
	return true;
}

stock void _Dynamic_ExpandIfRequired(ArrayList data, DynamicOffset offset, int blocksize, int length=1)
{
	// Used to expand internal object arrays by the _Dynamic_GetMemberDataOffset method
	int index = offset.Index;
	int cell = offset.Cell + length + 1;
	_Dynamic_RecalculateOffset(index, cell, blocksize);
	
	// Expand array if offset is outside of array bounds
	// Performance: Get array size should be replaced with an size counter
	// The above needs a really good think!!
	int size = GetArraySize(data);
	while (size <= index)
	{
		// -1 is the default value of unused memory to allow parenting via Set/PushObject
		int val = PushArrayCell(data, INVALID_DYNAMIC_OBJECT);
		size++;
		
		// This was added to ensure all memory is set to -1 for a parent resetting
		// -> this might impact performance and potentially cause parent resetting to be redone
		for (int block = 1; block < blocksize; block++)
		{
			SetArrayCell(data, val, INVALID_DYNAMIC_OBJECT, block);
		}
	}
}

stock Dynamic_MemberType _Dynamic_GetMemberDataType(ArrayList data, int position, int offset, int blocksize)
{
	return data.Get(position, offset);
}

stock void _Dynamic_SetMemberDataType(ArrayList data, DynamicOffset offset, int blocksize, Dynamic_MemberType type)
{
	// Set member type
	SetArrayCell(data, offset.Index, type, offset.Cell);
}

stock int _Dynamic_GetCollectionSize()
{
	return s_CollectionSize;
}

stock int _Dynamic_GetMemberCount(DynamicObject dynamic)
{
	if (!dynamic.IsValid(true))
		return 0;
	
	return dynamic.MemberCount;
}

stock DynamicOffset _Dynamic_GetMemberOffsetByIndex(DynamicObject dynamic, int memberindex)
{
	if (!dynamic.IsValid(true))
		return INVALID_DYNAMIC_OFFSET;
	
	return dynamic.MemberNames.Get(memberindex, g_iDynamic_MemberLookup_Offset);
}

stock Dynamic_MemberType _Dynamic_GetMemberType(DynamicObject dynamic, const char[] membername)
{
	if (!dynamic.IsValid(true))
		return DynamicType_Unknown;
	
	DynamicOffset offset;
	if (!_Dynamic_GetMemberDataOffset(dynamic, membername, false, offset, DynamicType_Unknown))
		return DynamicType_Unknown;
	
	return _Dynamic_GetMemberDataType(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize);
}

stock Dynamic_MemberType _Dynamic_GetMemberTypeByOffset(DynamicObject dynamic, DynamicOffset offset)
{
	if (!dynamic.IsValid(true))
		return DynamicType_Unknown;
	
	return _Dynamic_GetMemberDataType(dynamic.Data, offset.Index, offset.Cell, dynamic.BlockSize);
}

stock bool _Dynamic_GetMemberNameByIndex(DynamicObject dynamic, int memberindex, char[] buffer, int length)
{
	if (!dynamic.IsValid(true))
		return false;
	
	if (memberindex >= dynamic.MemberCount)
	{
		buffer[0] = '\0';
		return false;
	}
	
	GetArrayString(dynamic.MemberNames, memberindex, buffer, length);
	return true;
}

stock bool _Dynamic_GetMemberNameByOffset(DynamicObject dynamic, DynamicOffset offset, char[] buffer, int length)
{
	if (!dynamic.IsValid(true))
		return false;
	
	ArrayList membernames = dynamic.MemberNames;
	int membercount = membernames.Length;
	
	for (int i = 0; i < membercount; i++)
	{
		if (membernames.Get(i, g_iDynamic_MemberLookup_Offset) == offset)
		{
			membernames.GetString(i, buffer, length);
			return true;
		}
	}
	return false;
}

stock bool _Dynamic_SortMembers(DynamicObject dynamic, SortOrder order)
{
	if (!dynamic.IsValid(true))
		return false;
	
	int count = dynamic.MemberCount;
	if (count == 0)
		return false;
	
	// Dont bother sorting if there are no members
	ArrayList members = dynamic.MemberNames;
	StringMap offets = dynamic.Offsets;
	char[][] membernames = new char[count][DYNAMIC_MEMBERNAME_MAXLEN];
	DynamicOffset offset;
	
	// Get each membername into a string array
	for (int memberindex = 0; memberindex < count; memberindex++)
		GetArrayString(members, memberindex, membernames[memberindex], DYNAMIC_MEMBERNAME_MAXLEN);
	
	// Sort member names
	SortStrings(membernames, count, order);
	
	// Clear current member index lookup arrays
	ClearArray(members);
	
	// Rebuild member lookup arrays based on sorted membernames
	for (int memberindex = 0; memberindex < count; memberindex++)
	{
		if (!offets.GetValue(membernames[memberindex], offset))
			continue;
		
		memberindex = PushArrayString(members, membernames[memberindex]);
		SetArrayCell(members, memberindex, offset, g_iDynamic_MemberLookup_Offset);
	}
	return true;
}

stock Collection _Dynamic_FindByMemberValue(DynamicObject dynamic, DynamicObject params)
{
	if (!dynamic.IsValid(true))
		return null;
		
	// Iterate through child dynamic objects
	int membercount = dynamic.MemberCount;
	if (membercount == 0)
		return null;
	
	// All the required stuff
	Collection results = new Collection();
	DynamicObject member;
	int paramcount = params.MemberCount;
	bool matched = true;
	int resultcount = 0;
	DynamicOffset memberoffset;
	
	// Compile params
	char[][] param_name = new char[paramcount][DYNAMIC_MEMBERNAME_MAXLEN];
	Dynamic_MemberType[] param_type = new Dynamic_MemberType[paramcount];
	DynamicObject[] param_object = new DynamicObject[paramcount];
	DynamicOffset[] param_offset = new DynamicOffset[paramcount];
	int[] param_length = new int[paramcount];
	int[] param_operator = new int[paramcount];
	int param_maxlength;
	DynamicObject paramater;
	for (int i=0; i<paramcount; i++)
	{
		paramater = _Dynamic_GetDynamicByIndex(params, i);
		param_object[i] = paramater;
		_Dynamic_GetString(paramater, "MemberName", param_name[i], DYNAMIC_MEMBERNAME_MAXLEN);
		param_operator[i] = _Dynamic_GetInt(paramater, "Operator");
		param_offset[i] = _Dynamic_GetMemberOffset(paramater, "Value");
		param_type[i] = _Dynamic_GetMemberTypeByOffset(paramater, param_offset[i]);
		
		if (param_type[i] == DynamicType_String)
		{
			param_length[i] = _Dynamic_GetStringLengthByOffset(paramater, param_offset[i]);
			if (param_length[i] > param_maxlength)
				param_maxlength = param_length[i];
		}
	}
	char[] paramvalue = new char[param_maxlength];
	
	// Loop members in object
	for (int i = 0; i < membercount; i++)
	{
		// Get member offset and check its a dynamic object
		memberoffset = _Dynamic_GetMemberOffsetByIndex(dynamic, i);
		if (_Dynamic_GetMemberTypeByOffset(dynamic, memberoffset) != DynamicType_Dynamic)
			continue;
		
		// Get member and check its valid
		member = _Dynamic_GetDynamicByOffset(dynamic, memberoffset);
		if (!member.IsValid(false))
			continue;
		
		// Iterate through each param and check for matches
		matched = true;
		for (int param=0; param < paramcount; param++)
		{			
			switch (param_type[param])
			{
				case DynamicType_String:
				{
					_Dynamic_GetStringByOffset(param_object[param], param_offset[param], paramvalue, param_length[param]);
					memberoffset = _Dynamic_GetMemberOffset(member, param_name[param]);
					
					switch(param_operator[param])
					{
						case DynamicOperator_Equals:
						{
							if (!_Dynamic_CompareStringByOffset(member, memberoffset, paramvalue, true))
							{
								matched = false;
								break;
							}
						}
						case DynamicOperator_NotEquals:
						{
							if (_Dynamic_CompareStringByOffset(member, memberoffset, paramvalue, true))
							{
								matched = false;
								break;
							}
						}
						default:
						{
							ThrowError("DynamicOperator %d is not yet supported", param_operator[param]);
							return null;
						}
					}
				}
				default:
				{
					ThrowError("Dynamic_MemberType %d is not yet supported", param_type[param]);
					return null;
				}
			}
		}
		
		// Check result
		if (!matched)
			continue;
		
		results.Push(member);
		resultcount++;
	}
	
	if (resultcount == 0)
	{
		delete results;
		return null;
	}
	
	return results;
}
