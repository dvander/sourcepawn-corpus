//sm-build:17
#include <sourcemod>
#include <smjansson17>
#include <test17>

#define VERSION 		"0.0.2"


public Plugin:myinfo = {
	name 		= "SMJansson for SM 1.7, Testset",
	author 		= "Thrawn",
	description = "",
	version 	= VERSION,
};


public OnPluginStart() {

	Testset Tests = Testset(106);
	Tests.Ok(LibraryExists("jansson"), "Library is loaded");

	JSONObject hObj = JSONObject();
	Tests.Ok(Handle:hObj != INVALID_HANDLE, "Creating JSON Object");
	Tests.Ok(hObj.IsObject, "Type is Object");



	JSONString hString = JSONString("value");
	Tests.Ok(Handle:hString != INVALID_HANDLE, "Creating JSON String");
	Tests.Ok(hString.IsString, "Type is String");

	char sString[32];
	hString.Get(sString, sizeof(sString));
	Tests.IsString(sString, "value", "Checking created JSON String value");
	Tests.Ok(hString.Set("The answer is 42"), "Modifying string value");

	hString.Get(sString, sizeof(sString));
	Tests.IsString(sString, "The answer is 42", "Checking modified JSON String value");

	Tests.Ok(hObj.Set("__String", hString), "Attaching modified String to root object");
	delete(hString);



	JSONReal hReal = JSONReal(1.23456789);
	Tests.Ok(Handle:hReal != INVALID_HANDLE, "Creating JSON Real");
	Tests.Ok(hReal.IsReal, "Type is Real");

	Tests.IsFloat(hReal.Value, 1.23456789, "Checking created JSON Real value");
	Tests.IsFloat(hReal.FloatValue, 1.23456789, "Checking result of json_number_value");

	Tests.Ok(hReal.Set(-444.556), "Modifying real value");
	Tests.IsFloat(hReal.Value, -444.556, "Checking modified JSON Real value");
	Tests.IsFloat(hReal.FloatValue, -444.556, "Checking modified JSON Real value with json_number_value");

	Tests.Ok(hObj.Set("__Float", hReal), "Attaching modified Real to root object");
	delete(hReal);



	JSONInteger hInteger = JSONInteger(42);
	Tests.Ok(Handle:hInteger != INVALID_HANDLE, "Creating JSON Integer");
	Tests.Ok(hInteger.IsInteger, "Type is Integer");

	Tests.Is(hInteger.Value, 42, "Checking created JSON Integer value");
	Tests.IsFloat(hInteger.FloatValue, 42.0, "Checking result of json_number_value");

	Tests.Ok(hInteger.Set(1337), "Modifying integer value");
	Tests.Is(hInteger.Value, 1337, "Checking modified JSON Integer value");
	Tests.IsFloat(hInteger.FloatValue, 1337.0, "Checking modified result of json_number_value");

	Tests.Ok(hObj.Set("__Integer", hInteger), "Attaching modified Integer to root object");
	delete(hInteger);

	Tests.Is(hObj.Size, 3, "Object has the correct size");



	char sShouldBe[128] = "{\"__Float\": -444.55599975585938, \"__String\": \"The answer is 42\", \"__Integer\": 1337}";

	char sJSON[256];
	hObj.Dump(sJSON, sizeof(sJSON), 0);


	bool bJSONIsCorrect = true;
	bJSONIsCorrect = (bJSONIsCorrect && StrContains(sJSON, "\"__Float\": -444.55599975585938"));
	bJSONIsCorrect = (bJSONIsCorrect && StrContains(sJSON, "\"__String\": \"The answer is 42\""));
	bJSONIsCorrect = (bJSONIsCorrect && StrContains(sJSON, "\"__Integer\": 1337"));
	Tests.Ok(bJSONIsCorrect, "Created JSON contains the right elements");
	Tests.Is(strlen(sJSON), strlen(sShouldBe), "Created JSON has the correct length");


	JSONObject hObjNested = JSONObject();
	Tests.Ok(hObj.Set("__NestedObject", hObjNested), "Attaching new Object to root object");
	Tests.Is(hObj.Size, 4, "Object has the correct size");

	Tests.Ok(hObjNested.SetNew("__NestedString", JSONString("i am nested")), "Attaching new String to nested object (using reference stealing)");

	Tests.Ok(hObj.Delete("__Float"), "Deleting __Float element from root object");
	Tests.Is(hObj.Size, 3, "Object has the correct size");



	JSONArray hArray = JSONArray();
	Tests.Ok(Handle:hArray != INVALID_HANDLE, "Creating JSON Array");
	Tests.Ok(hArray.IsArray, "Type is Array");


	JSONString hFirst_String = json_string("1");
	JSONReal hSecond_Float = json_real(2.0);
	JSONInteger hThird_Integer = json_integer(3);
	JSONString hFourth_String = json_string("4");


	Tests.Ok(hArray.Append(hFirst_String), "Appending String to Array");
	Tests.Is(hArray.Size, 1, "Array has correct size");
	delete(hFirst_String);

	Tests.Ok(hArray.Append(hSecond_Float), "Appending Float to Array");
	Tests.Is(hArray.Size, 2, "Array has correct size");
	delete(hSecond_Float);

	Tests.Ok(hArray.Insert(0, hThird_Integer), "Inserting Integer at position 0");
	Tests.Is(hArray.Size, 3, "Array has correct size");
	delete(hThird_Integer);

	Tests.Ok(hArray.Set(1, hFourth_String), "Setting String at position 1");
	Tests.Is(hArray.Size, 3, "Array has correct size");
	delete(hFourth_String);

	Tests.Ok(hObjNested.Set("__Array", hArray), "Attaching Array to nested object");
	delete(hObjNested);

	PrintToServer("      - Creating the same Array using reference stealing");

	JSONArray hArrayStealing = JSONArray();
	Tests.Ok(hArrayStealing.AppendNew(json_string("1")), "Appending new String to Array");
	Tests.Ok(hArrayStealing.AppendNew(json_real(2.0)), "Appending new Float to Array");
	Tests.Ok(hArrayStealing.InsertNew(0, json_integer(3)), "Inserting new Integer at position 0");
	Tests.Ok(hArrayStealing.SetNew(1, json_string("4")), "Setting new String at position 1");

	Tests.Ok(hArray.Equal(hArrayStealing), "Arrays are equal.");
	delete(hArrayStealing);
	delete(hArray);

	if(FileExists("testoutput.json")) {
		DeleteFile("testoutput.json");
	}

	Tests.Ok(hObj.DumpFile("testoutput.json", 2), "File written without errors");
	Tests.Ok(FileExists("testoutput.json"), "Testoutput file exists");

	// Reload the written file
	JSONObject hReloaded = JSONObject:(json_load_file("testoutput.json"));
	Tests.Ok(Handle:hReloaded != INVALID_HANDLE, "Loading JSON from file.")
	Tests.Ok(hReloaded.Equal(hObj), "Written file and data in memory are equal");


	JSONObjectIterator hIterator = hReloaded.Iterator();
	Tests.Ok(Handle:hIterator != INVALID_HANDLE, "Creating an iterator for the reloaded object.")

	StringMap hTestTrie = StringMap();
	hTestTrie.SetValue("__String", _:JSON_STRING);
	hTestTrie.SetValue("__Integer", _:JSON_INTEGER);
	hTestTrie.SetValue("__NestedObject", _:JSON_OBJECT);

	while(Handle:hIterator != INVALID_HANDLE) {
		char sKey[128];
		hIterator.Key(sKey, sizeof(sKey));

		JSONNode hValue = hIterator.Get();

		char sType[32];
		hValue.TypeToString(sType, sizeof(sType));

		JSONType xShouldBeType;
		hTestTrie.GetValue(sKey, xShouldBeType);
		hTestTrie.Remove(sKey);

		PrintToServer("      - Found key: %s (Type: %s)", sKey, sType);
		Tests.Is(_:hValue.Type, _:xShouldBeType, "Type is correct");


		if(hValue.IsInteger) {
			JSONInteger hIntegerOverwrite = JSONInteger(9001);
			Tests.Ok(hIterator.Set(hReloaded, JSONNode:hIntegerOverwrite), "Overwriting integer value at iterator position");
			delete(hIntegerOverwrite);
		}

		if(hValue.IsString) {
			Tests.Ok(hIterator.SetNew(hReloaded, JSONString("What is the \"Hitchhiker's guide to the galaxy\"?")), "Overwriting string value at iterator position (using reference stealing)");
		}

		if(hValue.IsObject) {
			StringMap hTestTrieForArray = StringMap();
			hTestTrieForArray.SetValue("String", 0);
			hTestTrieForArray.SetValue("Integer", 0);
			hTestTrieForArray.SetValue("Real", 0);

			JSONArray hReloadedArray = JSONArray:((JSONObject:hValue).Get("__Array"));
			Tests.Ok(Handle:hReloadedArray != INVALID_HANDLE, "Getting JSON Array from reloaded object");
			Tests.Is(hReloadedArray.Size, 3, "Array has correct size");

			for(int iElement = 0; iElement < hReloadedArray.Size; iElement++) {
				JSONNode hElement = hReloadedArray.Get(iElement);

				char sArrayType[32];
				hElement.TypeToString(sArrayType, sizeof(sArrayType));

				PrintToServer("      - Found element with type: %s", sArrayType);
				hTestTrieForArray.Remove(sArrayType);
				delete(hElement);
			}

			Tests.Is(hTestTrieForArray.Size, 0, "Looped over all array elements");
			delete(hTestTrieForArray);

			Tests.Ok(hReloadedArray.Remove(2), "Deleting 3rd element from array");
			Tests.Is(hReloadedArray.Size, 2, "Array has correct size");

			JSONArray hArrayForExtending = JSONArray();
			JSONString hStringForExtension = JSONString("Extension 1");
			JSONString hStringForExtension2 = JSONString("Extension 2");
			hArrayForExtending.Append(hStringForExtension);
			hArrayForExtending.Append(hStringForExtension2);

			delete(hStringForExtension);
			delete(hStringForExtension2);

			Tests.Ok(hReloadedArray.Extend(hArrayForExtending), "Extending array");
			Tests.Is(hReloadedArray.Size, 4, "Array has correct size");

			Tests.Ok(hArrayForExtending.Clear(), "Clearing array");
			Tests.Is(hArrayForExtending.Size, 0, "Array is empty");

			delete(hArrayForExtending);
			delete(hReloadedArray);
		}

		delete(hValue);

		hIterator = hIterator.Next(hReloaded);
	}

	Tests.Is(hTestTrie.Size, 0, "Iterator looped over all keys");
	delete(hTestTrie);

	Tests.OkNot(hReloaded.Equal(hObj), "Written file and data in memory are not equal anymore");


	PrintToServer("      - Creating the same object using json_pack");
	ArrayList hParams = ArrayList(64);
	hParams.PushString(	"__String");
	hParams.PushString(	"What is the \"Hitchhiker's guide to the galaxy\"?");
	hParams.PushString(	"__Integer");
	hParams.Push(		9001);
	hParams.PushString(	"__NestedObject");
	hParams.PushString(	"__NestedString");
	hParams.PushString(	"i am nested");
	hParams.PushString( "__Array");
	hParams.Push(		3);
	hParams.PushString(	"4");
	hParams.PushString(	"Extension 1");
	hParams.PushString(	"Extension 2");

	JSONObject hPacked = JSONObject:JSONNode_ByPack("{ss,s:is{sss:[isss]}}", hParams);
	delete(hParams);

	Tests.Ok(hReloaded.Equal(hPacked), "Packed JSON is equal to manually created JSON");
	delete(hPacked);



	PrintToServer("      - Testing all JSONNode_ByPack values");
	ArrayList hParamsAll = ArrayList(64);
	hParamsAll.PushString("String");
	hParamsAll.Push(42);
	hParamsAll.Push(13.37);
	hParamsAll.Push(20001.333);
	hParamsAll.Push(true);
	hParamsAll.Push(false);

	JSONArray hPackAll = JSONArray:JSONNode_ByPack("[sifrbnb]", hParamsAll);
	Tests.Ok(hPackAll.IsArray, "Packed JSON is an array");

	char sElementOne[32];
	hPackAll.GetString(0, sElementOne, sizeof(sElementOne));

	Tests.IsString(sElementOne, "String", "Element 1 has the correct string value");
	Tests.Is(hPackAll.GetInteger(1), 42, "Element 2 has the correct integer value");
	Tests.IsFloat(hPackAll.GetFloat(2), 13.37, "Element 3 has the correct float value");
	Tests.IsFloat(hPackAll.GetFloat(3), 20001.333, "Element 4 has the correct float value");
	Tests.Is(hPackAll.GetBool(4), true, "Element 5 is boolean true.");

	JSONNode hElementFive = hPackAll.Get(5);
	Tests.Ok(hElementFive.IsNull, "Element 6 is null.");
	delete(hElementFive);

	Tests.Is(hPackAll.GetBool(6), false, "Element 7 is boolean false.");
	delete(hParamsAll);



	PrintToServer("      - Creating new object with 4 keys via load");
	JSONObject hObjManipulation = JSONObject:json_load("{\"A\":1,\"B\":2,\"C\":3,\"D\":4}");
	Tests.Ok(hObjManipulation.Delete("D"), "Deleting element from object");
	Tests.Is(hObjManipulation.Size, 3, "Object size is correct");


	PrintToServer("      - Creating new object to update the previous one");
	JSONObject hObjUpdate = JSONObject:json_load("{\"A\":10,\"B\":20,\"C\":30,\"D\":40,\"E\":50,\"F\":60,\"G\":70}");
	Tests.Ok(hObjManipulation.UpdateExisting(hObjUpdate), "Updating existing keys");


	JSONInteger hReadC = JSONInteger:(hObjManipulation.Get("C"));
	Tests.Is(hReadC.Value, 30, "Element update successful");
	Tests.Is(hObjManipulation.Size, 3, "Object size is correct");
	delete(hReadC);



	Tests.Ok(hObjManipulation.UpdateMissing(hObjUpdate), "Updating missing keys");

	JSONInteger hReadF = JSONInteger:(hObjManipulation.Get("F"));
	Tests.Is(hReadF.Value, 60, "Element insertion via update successful");
	Tests.Is(hObjManipulation.Size, 7, "Object size is correct");
	delete(hReadF);

	Tests.Ok(json_object_clear(hObjManipulation), "Clearing new object");
	Tests.Is(hObjManipulation.Size, 0, "Object is empty");


	PrintToServer("      - Adding one of the original four keys");

	JSONInteger hBNew = JSONInteger(2);
	hObjManipulation.Set("B", hBNew);

	Tests.Ok(hObjManipulation.Update(hObjUpdate), "Updating all keys");
	delete(hBNew);
	delete(hObjUpdate);


	JSONInteger hReadB = JSONInteger:(hObjManipulation.Get("B"));
	Tests.Is(hReadB.Value, 20, "Element update successful");
	delete(hReadB);

	Tests.Is(hObjManipulation.Size, 7, "Object size is correct");





	PrintToServer("      - Creating and adding an array to the object");
	JSONArray hCopyArray = JSONArray();
	JSONString hNoMoreVariableNames = JSONString("no more!");
	JSONString hEvenLessVariableNames = json_string("less n less!");

	hCopyArray.Append(hNoMoreVariableNames);
	hCopyArray.Append(hEvenLessVariableNames);
	hObjManipulation.Set("Array", hCopyArray);

	JSONObject hCopy = JSONObject:hObjManipulation.Copy();

	Tests.Ok(Handle:hCopy != INVALID_HANDLE, "Creating copy of JSON Object");
	Tests.Is(hCopy.Size, 8, "Object size is correct");
	Tests.Ok(hCopy.Equal(hObjManipulation), "Objects are equal");


	PrintToServer("      - Modifying the array of the original Object");
	JSONString hEmptyVariableNames = JSONString("empty!");
	hCopyArray.Append(hEmptyVariableNames);

	Tests.Ok(hCopy.Equal(hObjManipulation), "Content of copy is still identical (was a shallow copy)");


	JSONObject hDeepCopy = JSONObject:hObjManipulation.Copy(true);
	Tests.Ok(Handle:hDeepCopy != INVALID_HANDLE, "Creating deep copy of JSON Object");
	Tests.Is(hDeepCopy.Size, 8, "Object size is correct");
	Tests.Ok(hDeepCopy.Equal(hObjManipulation), "Objects are equal");


	PrintToServer("      - Modifying the array of the original Object");
	JSONString hDeadVariableNames = JSONString("dead!");
	hCopyArray.Append(hDeadVariableNames);
	delete(hCopyArray);

	Tests.OkNot(hDeepCopy.Equal(hObjManipulation), "Content of copy is not identical anymore (was a deep copy)");


	JSONObject hBooleanObject = JSONObject();
	hBooleanObject.SetNew("true1", json_true());
	hBooleanObject.SetNew("false1", json_false());
	hBooleanObject.SetNew("true2", json_boolean(true));
	hBooleanObject.SetNew("false2", json_boolean(false));
	hBooleanObject.SetNew("null", json_null());

	char sBooleanObjectDump[4096];
	hBooleanObject.Dump(sBooleanObjectDump, sizeof(sBooleanObjectDump), 0);

	char sBooleanShouldBe[4096] = "{\"false2\": false, \"true1\": true, \"false1\": false, \"true2\": true, \"null\": null}";
	bool bBooleanObjectIsCorrect = true;
	bBooleanObjectIsCorrect = (bBooleanObjectIsCorrect && StrContains(sBooleanObjectDump, "\"false2\": false"));
	bBooleanObjectIsCorrect = (bBooleanObjectIsCorrect && StrContains(sBooleanObjectDump, "\"true1\": true"));
	bBooleanObjectIsCorrect = (bBooleanObjectIsCorrect && StrContains(sBooleanObjectDump, "\"false1\": false"));
	bBooleanObjectIsCorrect = (bBooleanObjectIsCorrect && StrContains(sBooleanObjectDump, "\"null\": null"));

	Tests.Ok(bBooleanObjectIsCorrect, "Created JSON contains the right elements");
	Tests.Is(strlen(sBooleanObjectDump), strlen(sBooleanShouldBe), "Created JSON has the correct length");

	delete(hBooleanObject);


	char sErrorMsg[255];
	int iLine = -1;
	int iColumn = -1;
	JSONNode hNoObj = json_load_ex("{\"apple\": 3 \"banana\": 0, \"error\": \"missing a comma\"}", sErrorMsg, sizeof(sErrorMsg), iLine, iColumn);

	if(Handle:hNoObj == INVALID_HANDLE) {
		Tests.Pass("Invalid JSON resulted in an invalid JSONNode");
		Tests.Is(iLine, 1, "Correct error line");
		Tests.Is(iColumn, 20, "Correct error column");
		Tests.Ok(strlen(sErrorMsg) > 0, "Error message is not empty");
	} else {
		Tests.Fail("Invalid JSON resulted in an invalid JSONNode");
		delete(hNoObj);
	}

	Tests.End();

	delete(Tests);
}