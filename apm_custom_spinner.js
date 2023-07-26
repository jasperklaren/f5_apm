define(["require", "exports", "tslib", "module", "apmui/page/logon/View"], function (require, exports, tslib_1, module, View_1) {
    "use strict";
    Object.defineProperty(exports, "__esModule", { value: true });
    requirejs.config({
        map: {
            'apmui/master/View': {
                'apmui/page/logon/View': module.id,
            },
        },
    });
    /* Replacement View component */
    var CustomLogonView = /** @class */ (function (_super) {
        tslib_1.__extends(CustomLogonView, _super);
        function CustomLogonView() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        CustomLogonView.prototype.componentDidMount = function () {
            _super.prototype.componentDidMount.call(this);
            /* *****INSERT CUSTOM JAVASCRIPT HERE***** */
            const btn = document.querySelector('.apmui-button-submit');
            let form = document.querySelector('.apmui-form')
            let message = document.querySelector('.apmui-content');
            btn.addEventListener('click', function(event){
               form.style.display = 'none';
               const spinner = document.createElement('div');
               spinner.classList.add('loader');
               const textdiv = document.createElement('div');
               textdiv.innerText = 'Open Authenticator App';
               message.appendChild(spinner);
               message.appendChild(textdiv);
            });
          /* **************************************** */
        };
        return CustomLogonView;
    }(View_1.default));
    exports.default = CustomLogonView;
});
