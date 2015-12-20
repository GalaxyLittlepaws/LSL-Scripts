// :CATEGORY:HTTP
// :NAME:Permanent_HTTPIN_URL_persister
// :AUTHOR:donjr Spiegelblatt
// :CREATED:2012-06-16 03:41:32.957
// :EDITED:2013-09-18 15:38:59
// :ID:621
// :NUM:845
// :REV:1.0
// :WORLD:Second Life
// :DESCRIPTION:
// When you need to pass data into SL from outside, the first problem you will encounter is that llRequestURL() generates a new URL every time the script is reset, de-rezzed or the region the primitive is restarted. It becomes very difficult to keep track of the URLs and it would be easier if there were some permanent pointer that could be updated every time the primitive's URL changes.
// Create a primitive and a new script in that primitive.
// Copy the code from the code section below and paste it into the new script in that primitive.
// Configure the script to set-up your custom url, user name and API key.
// Configuration
// There are several options you can configure in the CONFIGURATION section:
// string CUSTOM_URL = "ksim";
// string USER_NAME = "kve";
// string API_KEY = "fbf9ra57-5d54-9fbg-89fd-711bc7b163c3";
Where USER_NAME is the name you used to sign-up on http://tiny.cc, API_KEY is the API key generated by visiting http://tiny.cc/api-docs and CUSTOM_URL is the short descriptive name of the simulator URL.
For example, the configuration above will create and update the primitive's URL, setting it to: http://tiny.cc/evesim
// Code
// 
// Note there is a limit of 500 calls a day, but it really only serves as a NAME-SERVER
// :CODE:
//////////////////////////////////////////////////////////
// [K] Kira Komarov - 2011, License: GPLv3              //
// Please see: http://www.gnu.org/licenses/gpl.html     //
// for legal details, rights of fair usage and          //
// the disclaimer and warranty conditions.              //
//////////////////////////////////////////////////////////
 
// With modification by: Donjr Spiegelblatt
 
//////////////////////////////////////////////////////////
//                   CONFIGURATION                      //
//////////////////////////////////////////////////////////
// This is the url extension, ie http://tiny.cc/biose.
string CUSTOM_URL = "hotrod";
// Set this to the username you signed up with on 
// http://tiny.cc.
string USER_NAME = "hotrod";
// Set this to the API key generatred by tiny.cc. To
// generate one, visit: http://tiny.cc/api-docs and you
// will see Your "API Key:" followed by a key.
string API_KEY = "0000000-0000-0000-0000-000000000";
//////////////////////////////////////////////////////////
//                     INTERNALS                        //
//////////////////////////////////////////////////////////

key rlReq = NULL_KEY;
key glReq = NULL_KEY;
string smURL = "";

key TinyRequest(integer type)
{
    string url = "http://tiny.cc/"
                 + "?c=rest_api"
                 + "&format=json"
                 + "&version=2.0.3";
    if(type)                        // this was the minor difference between the two two calls
        url += "&m=shorten";
    else
    {
        url += "&m=edit"
             + "&hash=" + CUSTOM_URL;
    }
    url += "&login=" + USER_NAME
         + "&apiKey=" + API_KEY
         + "&shortUrl=" + CUSTOM_URL
         + "&longUrl=" + llEscapeURL(smURL + "/get_url");
    return  llHTTPRequest( url, [HTTP_METHOD, "GET"], "");
}

default
{
    state_entry()
    {
        llRequestURL();
    }
    on_rez(integer param)
    {
        llResetScript();
    }

    http_request(key id, string method, string body)
    {
        if (method == URL_REQUEST_GRANTED)
        {
            smURL = body;
            rlReq = TinyRequest(TRUE);      // tiny request first goes here and not in a timer event
        }
        else if(method == URL_REQUEST_DENIED)
        {
            llOwnerSay("ERROR: URL REQUEST was DENIED "+body);
            llSleep(5);
            llResetScript();
        }
        else if(method == "GET")
        {
            string resp = "GET";
            llSay(0, "x-path-info    ="+llGetHTTPHeader(id, "x-path-info"));
            llSay(0, "x-query-string ="+llGetHTTPHeader(id, "x-query-string"));
            if(llGetHTTPHeader(id, "x-path-info") ==  "/get_url")
                llHTTPResponse(id, 200,"URL="+smURL+"/cmd");
            else if(llGetHTTPHeader(id, "x-path-info") ==  "/cmd")
            {
                // example of handling a parameter
                if(llGetHTTPHeader(id, "x-query-string") == "name" )
                    resp = llGetObjectName();
                if(llGetHTTPHeader(id, "x-query-string") == "sim" )
                    resp = llGetRegionName();
                llHTTPResponse(id, 200, resp);
            }
            else
                llHTTPResponse(id, 501, "Unknown call");
        }
        else if(method == "POST")
        {
            string resp = "POST";
            llHTTPResponse(id, 200, resp);
        }
        else
        {
                    //          \/ 501 Not Implemented        (not real sure if this is even possible)
            llHTTPResponse(id, 501, "Not Implemented "+method);
        }
    }
    http_response(key request_id, integer status, list metadata, string body)
    {
        if (glReq == request_id)
        {
            if(status != 200)
                llOwnerSay("TinyRequest(FALSE) failed status="+(string)status+" "+body);
            glReq = NULL_KEY;       // the same event sometimes shows up more then once
        }
        else if(rlReq == request_id)
        {
            rlReq = NULL_KEY;       // the same event sometimes shows up more then once 
            if(status != 200)
                llOwnerSay("TinyRequest(TRUE) failed status="+(string)status+" "+body);
            if(~llSubStringIndex(body, "1215"))
                glReq = TinyRequest(FALSE);
        }
        // llHTTPResponse(request_id, 200, "");  Not require and in fact invalid in this event
    }
}