/*
 * Copyright (C) 2011 Keijiro Takahashi
 * Copyright (C) 2012 GREE, Inc.
 * 
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 * 
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 * 
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

using Callback = System.Action<string>;                    // message
using OnFinishCallback = System.Action;                    // no arguments
using OnFailCallback = System.Action<int, string, string>; // errorCode, errorDomain, errorMessage

#if UNITY_EDITOR || UNITY_STANDALONE_OSX
public class UnitySendMessageDispatcher
{
	public static void Dispatch(string name, string method, string message)
	{
		GameObject obj = GameObject.Find(name);
		if (obj != null)
			obj.SendMessage(method, message);
	}
}
#endif

public class WebViewObject : MonoBehaviour
{
	Callback callback;
	OnFinishCallback onFinishCallback;
	OnFailCallback onFailCallback;
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
	IntPtr webView;
	bool visibility;
	Rect rect;
	Texture2D texture;
	string inputString;
#elif UNITY_IPHONE
	IntPtr webView;
#elif UNITY_ANDROID
	AndroidJavaObject webView;
	Vector2 offset;
#endif

#if UNITY_EDITOR || UNITY_STANDALONE_OSX
	[DllImport("WebView")]
	private static extern IntPtr _WebViewPlugin_Init(
		string gameObject, int width, int height, bool ineditor);
	[DllImport("WebView")]
	private static extern int _WebViewPlugin_Destroy(IntPtr instance);
	[DllImport("WebView")]
	private static extern void _WebViewPlugin_SetRect(IntPtr instance, int width, int height);
	[DllImport("WebView")]
	private static extern void _WebViewPlugin_SetVisibility(
		IntPtr instance, bool visibility);
	[DllImport("WebView")]
	private static extern void _WebViewPlugin_LoadURL(
		IntPtr instance, string url);
	[DllImport("WebView")]
	private static extern void _WebViewPlugin_ReloadURL(
		IntPtr instance);
	[DllImport("WebView")]
	private static extern void _WebViewPlugin_EvaluateJS(
		IntPtr instance, string url);
	[DllImport("WebView")]
	private static extern void _WebViewPlugin_Update(IntPtr instance,
		int x, int y, float deltaY, bool down, bool press, bool release,
		bool keyPress, short keyCode, string keyChars, int textureId);
	
	
#elif UNITY_IPHONE
	[DllImport("__Internal")]
	private static extern IntPtr _WebViewPlugin_Init(string gameObject);
	[DllImport("__Internal")]
	private static extern int _WebViewPlugin_Destroy(IntPtr instance);
	[DllImport("__Internal")]
	private static extern void _WebViewPlugin_SetMargins(
		IntPtr instance, int left, int top, int right, int bottom);
	[DllImport("__Internal")]
	private static extern void _WebViewPlugin_SetVisibility(
		IntPtr instance, bool visibility);
	[DllImport("__Internal")]
	private static extern void _WebViewPlugin_SetBackgroundColor(
		IntPtr instance,float r, float g, float b, float a, bool opaque);
	[DllImport("__Internal")]
	private static extern void _WebViewPlugin_LoadURL(
		IntPtr instance, string url);
	[DllImport("__Internal")]
	private static extern void _WebViewPlugin_ReloadURL(
		IntPtr instance);
	[DllImport("__Internal")]
	private static extern void _WebViewPlugin_EvaluateJS(
		IntPtr instance, string url);
	[DllImport("__Internal")]
	private static extern void _WebViewPlugin_SetFrame(
		IntPtr instance, int x , int y , int width , int height);
	[DllImport("__Internal")]
	private static extern void _WebViewPlugin_SetScrollable(IntPtr instance, bool scrollable);
	[DllImport("__Internal")]
	private static extern void _WebViewPlugin_SetBounceMode(IntPtr instance,bool vertical,bool horizontal);
	[DllImport("__Internal")]
	private static extern void _WebViewPlugin_SetDelaysTouchEnable(IntPtr instance,bool deferrable);
#endif

#if UNITY_EDITOR || UNITY_STANDALONE_OSX
	private void CreateTexture(int x, int y, int width, int height)
	{
		int w = 1;
		int h = 1;
		while (w < width)
			w <<= 1;
		while (h < height)
			h <<= 1;
		//Debug.Log ("w" +w +" h" + h);
		rect = new Rect(x, y, width, height);
		texture = new Texture2D(w, h, TextureFormat.ARGB32, false);
	}
#endif

	public void Init(Callback cb = null, OnFinishCallback finishcb = null, OnFailCallback failcb = null)
	{
		callback = cb;
		onFinishCallback = finishcb;
		onFailCallback = failcb;
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
		CreateTexture(0, 0, Screen.width/2, Screen.height/2);
		webView = _WebViewPlugin_Init(name, Screen.width, Screen.height,
			Application.platform == RuntimePlatform.OSXEditor);
#elif UNITY_IPHONE
		webView = _WebViewPlugin_Init(name);
#elif UNITY_ANDROID
		offset = new Vector2(0, 0);
		webView = new AndroidJavaObject("net.gree.unitywebview.WebViewPlugin");
		webView.Call("Init", name);
#endif
	}
	
	// TODO: Should rename to SetCenterPositionWithSize or something, because
	//       the second argument does nothing related to the scale, it's just a size.
	// Set the position and size of this web view.
	// The origin of the view is Top-Left (same to the iOS/Android) even if its running on OS X.
	public void SetCenterPositionWithScale(Vector2 center, Vector2 size)
	{
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
		int left = (int)center.x + Screen.width/2 - (int)size.x/2;
		int bottom = (int)center.y + (int)size.y/2;
		
		int width = (int)size.x;
		int height = (int)size.y;
		CreateTexture(left, bottom, width, height);
		_WebViewPlugin_SetRect(webView, width, height);
#elif UNITY_IPHONE
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_SetFrame(webView,(int)center.x,(int)center.y,(int)size.x,(int)size.y);
#elif UNITY_ANDROID
		if (webView == null)
			return;
		// TODO: Not implemented in Android
#endif
	}
	
	public void SetBackgroundColor(Color color , bool opaque){
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
		// TODO: Not implemented properly.
#elif UNITY_IPHONE
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_SetBackgroundColor(webView,color.r,color.g,color.b,color.a,opaque);
#elif UNITY_ANDROID
		if (webView == null)
			return;
		// TODO: Not implemented in Android
#endif
	}
	
	public void SetScrollable(bool scrollable){
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
		// Do nothing on OS X
#elif UNITY_IPHONE
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_SetScrollable(webView,scrollable);
#elif UNITY_ANDROID
		if (webView == null)
			return;
		// TODO: Not implemented in Android
#endif

	}
	
	public void SetBounceMode(bool vertical,bool horizontal){
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
		// Do nothing on OS X
#elif UNITY_IPHONE
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_SetBounceMode(webView,vertical,horizontal);
#elif UNITY_ANDROID
			if (webView == null)
				return;
			// TODO: Not implemented in Android
#endif
	}
	
	public void SetDelaysTouchesEnable(bool defferrable){
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
		// Do nothing on OS X
#elif UNITY_IPHONE
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_SetDelaysTouchEnable(webView,defferrable);
#elif UNITY_ANDROID
		if (webView == null)
			return;
		// TODO: Not implemented in Android
#endif
	}
	void OnDestroy()
	{
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_Destroy(webView);
#elif UNITY_IPHONE
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_Destroy(webView);
#elif UNITY_ANDROID
		if (webView == null)
			return;
		webView.Call("Destroy");
#endif
	}

	public void SetMargins(int left, int top, int right, int bottom)
	{
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
		if (webView == IntPtr.Zero)
			return;
		int width = Screen.width - (left + right);
		int height = Screen.height - (bottom + top);
		CreateTexture(left, bottom, width, height);
		_WebViewPlugin_SetRect(webView, width, height);
#elif UNITY_IPHONE
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_SetMargins(webView, left, top, right, bottom);
#elif UNITY_ANDROID
		if (webView == null)
			return;
		offset = new Vector2(left, top);
		webView.Call("SetMargins", left, top, right, bottom);
#endif
	}

	public void SetVisibility(bool v)
	{
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
		if (webView == IntPtr.Zero)
			return;
		visibility = v;
		_WebViewPlugin_SetVisibility(webView, v);
#elif UNITY_IPHONE
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_SetVisibility(webView, v);
#elif UNITY_ANDROID
		if (webView == null)
			return;
		webView.Call("SetVisibility", v);
#endif
	}

	public void LoadURL(string url)
	{
#if UNITY_EDITOR || UNITY_STANDALONE_OSX || UNITY_IPHONE
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_LoadURL(webView, url);
#elif UNITY_ANDROID
		if (webView == null)
			return;
		webView.Call("LoadURL", url);
#endif
	}

	public void ReloadURL(){
#if UNITY_EDITOR || UNITY_STANDALONE_OSX || UNITY_IPHONE
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_ReloadURL(webView);
#elif UNITY_ANDROID
		if (webView == null)
			return;
		// TODO: Not implemented in Android
#endif
	}

	public void EvaluateJS(string js)
	{
#if UNITY_EDITOR || UNITY_STANDALONE_OSX || UNITY_IPHONE
		if (webView == IntPtr.Zero)
			return;
		_WebViewPlugin_EvaluateJS(webView, js);
#elif UNITY_ANDROID
		if (webView == null)
			return;
		webView.Call("LoadURL", "javascript:" + js);
#endif
	}

	// Following URL schemes are supported for iOS/Mac
	//   - unity:  (message = schemeless URL)
	//   - dandg:  (message = complete URL with original scheme)
	//   - ohttp:  (message = complete URL with original scheme)
	//   - ohttps: (message = complete URL with original scheme)
	// For Android, call window.Unity.call(message) from JavaScript, not to use URL
	public void CallFromJS(string message)
	{
		if (callback != null)
			callback(message);
	}

	// TODO: Not implemented in Android
	// TODO: Not implemented in Mac OS X
	public void CallOnFinish(string _)
	{
		if (onFinishCallback != null)
			onFinishCallback();
	}

	// TODO: Not implemented in Android
	// TODO: Not implemented in Mac OS X
	public void CallOnFail(string message)
	{
		if (onFailCallback != null)
		{
			int errorCode = 0;
			string errorDomain = "";
			string errorMessage = "";
#if UNITY_IPHONE
			string[] parameters = message.Split ('|');
			errorCode = parameters[0].ToInt32();
			errorDomain = parameters[1];
			errorMessage = parameters[2];
#endif
			onFailCallback(errorCode, errorDomain, errorMessage);
		}
	}

#if UNITY_EDITOR || UNITY_STANDALONE_OSX
	void Update()
	{
		inputString += Input.inputString;
	}

	void OnGUI()
	{
		if (webView == IntPtr.Zero || !visibility)
			return;

		Vector3 pos = Input.mousePosition;
		bool down = Input.GetButton("Fire1");
		bool press = Input.GetButtonDown("Fire1");
		bool release = Input.GetButtonUp("Fire1");
		float deltaY = Input.GetAxis("Mouse ScrollWheel");
		bool keyPress = false;
		string keyChars = "";
		short keyCode = 0;
		if(inputString != null){
			if (inputString.Length > 0) {
				keyPress = true;
				keyChars = inputString.Substring(0, 1);
				keyCode = (short)inputString[0];
				inputString = inputString.Substring(1);
			}
		}
		_WebViewPlugin_Update(webView,
			(int)(pos.x - rect.x), (int)(pos.y - rect.y), deltaY,
			down, press, release, keyPress, keyCode, keyChars,
			texture.GetNativeTextureID());
		GL.IssuePluginEvent((int)webView);
		Matrix4x4 m = GUI.matrix;
		GUI.matrix = Matrix4x4.TRS(new Vector3(0, Screen.height, 0),
			Quaternion.identity, new Vector3(1, -1, 1));
		GUI.DrawTexture(rect, texture);
		GUI.matrix = m;
	}
#endif
}
