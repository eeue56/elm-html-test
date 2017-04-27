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

    return {
        toJson: function(html) {
            return forceThunks(html);
        },
        eventDecoder: F2(function (eventName, events) {
            var event = events[eventName];
            if (!event) return _elm_lang$core$Result$Err('Event ' + eventName + ' not found');

            return _elm_lang$core$Result$Ok(event.decoder);
        })
    };
})();
