Elm.Native = Elm.Native || {};
Elm.Native.History = {};
Elm.Native.History.make = function(localRuntime){

  localRuntime.Native = localRuntime.Native || {};
  localRuntime.Native.History = localRuntime.Native.History || {};

  if (localRuntime.Native.History.values){
    return localRuntime.Native.History.values;
  }

  var NS = Elm.Native.Signal.make(localRuntime);
  var Task = Elm.Native.Task.make(localRuntime);
  var Utils = Elm.Native.Utils.make(localRuntime);
  var node = window;

  // path : Signal String
  var path = NS.input('History.path', window.location.pathname);

  // length : Signal Int
  var length = NS.input('History.length', window.history.length);

  // hash : Signal String
  var hash = NS.input('History.hash', window.location.hash);

  localRuntime.addListener([path.id, length.id], node, 'popstate', function getPath(event){
    localRuntime.notify(path.id, window.location.pathname);
    localRuntime.notify(length.id, window.history.length);
    localRuntime.notify(hash.id, window.location.hash);
  });

  localRuntime.addListener([hash.id], node, 'hashchange', function getHash(event){
    localRuntime.notify(hash.id, window.location.hash);
  });

  // setPath : String -> Task error ()
  var setPath = function(urlpath){
    return Task.asyncFunction(function(callback){
      setTimeout(function(){
        localRuntime.notify(path.id, urlpath);
        window.history.pushState({}, "", urlpath);
        localRuntime.notify(hash.id, window.location.hash);
        localRuntime.notify(length.id, window.history.length);

      },0);
      return callback(Task.succeed(Utils.Tuple0));
    });
  };

  // replacePath : String -> Task error ()
  var replacePath = function(urlpath){
    return Task.asyncFunction(function(callback){
      setTimeout(function(){
        localRuntime.notify(path.id, urlpath);
        window.history.replaceState({}, "", urlpath);
        localRuntime.notify(hash.id, window.location.hash);
        localRuntime.notify(length.id, window.history.length);
      },0);
      return callback(Task.succeed(Utils.Tuple0));
    });
  };

  // go : Int -> Task error ()
  var go = function(n){
    return Task.asyncFunction(function(callback){
      setTimeout(function(){
        window.history.go(n);
        localRuntime.notify(length.id, window.history.length);
        localRuntime.notify(hash.id, window.location.hash);
      }, 0);
      return callback(Task.succeed(Utils.Tuple0));
    });
  };

  // back : Task error ()
  var back = Task.asyncFunction(function(callback){
    setTimeout(function(){
      localRuntime.notify(hash.id, window.location.hash);
      window.history.back();
      localRuntime.notify(length.id, window.history.length);

    }, 0);
    return callback(Task.succeed(Utils.Tuple0));
  });

  // forward : Task error ()
  var forward = Task.asyncFunction(function(callback){
    setTimeout(function(){
      window.history.forward();
      localRuntime.notify(length.id, window.history.length);
      localRuntime.notify(hash.id, window.location.hash);
    }, 0);
    return callback(Task.succeed(Utils.Tuple0));
  });



  return {
    path        : path,
    setPath     : setPath,
    replacePath : replacePath,
    go          : go,
    back        : back,
    forward     : forward,
    length      : length,
    hash        : hash
  };

};
