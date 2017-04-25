var _eeue56$elm_html_test$Native_HtmlAsJson = (function() {
    function forceThunks(vNode) {
        if (typeof vNode !== 'undefined' && vNode.type === 'thunk' && !vNode.node) {
            vNode.node = vNode.thunk.apply(vNode.thunk, vNode.args);
        }
        if (typeof vNode !== 'undefined' && typeof vNode.children !== 'undefined') {
            vNode.children = vNode.children.map(forceThunks);
        }
        return vNode;
    }

    // stringify needed to strip functions - can performance-optimize this later!
    return {
        toJsonString: function(html) {
            var asString = JSON.stringify(forceThunks(html));

            if (typeof asString === "undefined"){
                return "";
            }
            return asString;
        },
        getEventDecoder: F2(function (name, events) {
            var event = events[name];
            if (!event) return { ctor: 'Nothing' };

            return {
              ctor: 'Just',
              _0: event.decoder
            }
        })
    };
})();
