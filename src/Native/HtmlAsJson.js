var _eeue56$elm_html_test$Native_HtmlAsJson = (function() {
    function forceThunks(vNode) {
        switch (vNode.type)
        {
            case 'thunk':
                if (!vNode.node) {
                    vNode.node = vNode.thunk();
                    forceThunks(vNode.node);
                }
                return;

            case 'tagger':
                forceThunks(vNode.node);
                return;

            case 'text':
                return;

            case 'node':
                var children = vNode.children;

                for (var i = 0; i < children.length; i++) {
                    forceThunks(children[i]);
                }

                return;

            case 'keyed-node':
                var children = vNode.children;

                for (var i = 0; i < children.length; i++) {
                    forceThunks(children[i]);
                }

                return domNode;

            case 'custom':
                return;

            default:
                throw new Error('Unknown virtual-dom node type: ' + vNode.type);
        }
    }

    // stringify needed to strip functions - can performance-optimize this later!
    return {
        toJsonString: function(html) {
            forceThunks(html);
            var asString = JSON.stringify(html);

            if (typeof asString === "undefined"){
                return "";
            }
            return asString;
        }
    };
})();
