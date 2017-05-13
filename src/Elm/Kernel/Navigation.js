/*

import Elm.Kernel.Scheduler exposing (binding, succeed)
import Elm.Kernel.Utils exposing (Tuple0)

*/


// FAKE NAVIGATION

function _Navigation_go(n)
{
	return __Scheduler_binding(function(callback)
	{
		if (n !== 0)
		{
			history.go(n);
		}
		callback(__Scheduler_succeed(__Utils_Tuple0));
	});
}

function _Navigation_pushState(url)
{
	return __Scheduler_binding(function(callback)
	{
		history.pushState({}, '', url);
		callback(__Scheduler_succeed(getLocation()));
	});
}

function _Navigation_replaceState(url)
{
	return __Scheduler_binding(function(callback)
	{
		history.replaceState({}, '', url);
		callback(__Scheduler_succeed(getLocation()));
	});
}


// REAL NAVIGATION

function _Navigation_reloadPage(skipCache)
{
	return __Scheduler_binding(function(callback)
	{
		document.location.reload(skipCache);
		callback(__Scheduler_succeed(__Utils_Tuple0));
	});
}

function _Navigation_setLocation(url)
{
	return __Scheduler_binding(function(callback)
	{
		try
		{
			window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			document.location.reload(false);
		}
		callback(__Scheduler_succeed(__Utils_Tuple0));
	});
}


// GET LOCATION

function _Navigation_getLocation()
{
	var location = document.location;

	return {
		href: location.href,
		host: location.host,
		hostname: location.hostname,
		protocol: location.protocol,
		origin: location.origin,
		port_: location.port,
		pathname: location.pathname,
		search: location.search,
		hash: location.hash,
		username: location.username,
		password: location.password
	};
}


// DETECT IE11 PROBLEMS

function _Navigation_isInternetExplorer11()
{
	return window.navigator.userAgent.indexOf('Trident') !== -1;
}
