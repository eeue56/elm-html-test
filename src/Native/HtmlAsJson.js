var _eeue56$elm_html_test$Native_HtmlAsJson = (function() {
    // stringify needed to strip functions - can performance-optimize this later!
    return {
        toJsonString: function(html) {
            var asString = JSON.stringify(html);

            if (typeof asString === "undefined"){
                return "";
            }
            return asString;
        }
    };
})();
