var _eeue56$elm_html_test$Native_HtmlAsJson = (function() {
    function forceThunks(key, vNode) {
        if (typeof vNode !== 'undefined' && vNode.type === 'thunk' && !vNode.node) {
            vNode.node = vNode.thunk.apply(vNode.thunk, vNode.args);
            return vNode;
        } else {
            return vNode;
        }
    }

    // stringify needed to strip functions - can performance-optimize this later!
    return {
        toJsonString: function(html) {
            var asString = JSON.stringify(html, forceThunks);

            if (typeof asString === "undefined"){
                return "";
            }
            return asString;
        }
    };
})();
