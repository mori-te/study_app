const VueCodemirror = window.VueCodemirror;
Vue.use(VueCodemirror);
var vm = new Vue({
    el: "#app",
    data: {
        source: "",
        result: "-",
        lang: 'java',
        cmOptions: {
            tabSize: 4,
            lineNumbers: true,
            indentUnit: 4,
            viewportMargin: 20,
            mode: 'javascript',
            theme: 'lesser-dark'
        }
    },
    methods: {
        exec: function () {
            axios.post('exec_' + vm.lang, {
                user: "mori-te",
                lang: vm.lang,
                source: vm.source
            }).then(function (response) {
                vm.result = response.data.result;
            });
        },
        change: function () {
            axios.get("lang?lang=" + this.lang)
            .then(function(response) {
                vm.cmOptions.mode = response.data.lang;
                vm.cmOptions.tabSize = response.data.indent;
                vm.cmOptions.indentUnit = response.data.indent;
                vm.source = response.data.source;
            });
        }
    },
    mounted() {
        this.change();
    }
})