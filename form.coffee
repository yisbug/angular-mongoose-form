# 根据schema和data，自动生成表单

angular.module 'angular.mongoose.form',[]
.run ['$templateCache',($templateCache)->
    $templateCache.put 'template/form.add.html','''
    <div class="modal-header">
        <h4 class="modal-title">{{title}}</h4>
    </div>
    <div class="modal-body">
        <form class="form-horizontal" role="form" ng-submit="submit()">
            <div class="form-group" ng-repeat="row in rows" ng-if="row.if && !row.isHide">
                <label class="col-sm-3 control-label">{{row.name}}</label>
                <div class="col-sm-9" ng-if="row.style=='input'">
                    <input type="text" class="form-control"  placeholder="{{row.placeholder}}" name="{{row.field}}" ng-model="data[row.field]" >
                    {{row.help}}
                </div>
                <div class="col-sm-9" ng-if="row.style=='password'">
                    <input type="password" class="form-control"  placeholder="{{row.placeholder}}" name="{{row.field}}" ng-model="data[row.field]" >
                    {{row.help}}
                </div>
                <div class="col-sm-9" ng-if="row.style == 'radio'">
                    <div class="btn-group">
                        <label ng-repeat="value in row.enum" class="btn btn-primary" ng-model="data[row.field]" btn-radio="'{{value}}'">{{row.names[$index]}}</label>
                    </div>
                    {{row.help}}
                </div>
                <div class="col-sm-9" ng-if="row.style == 'date'">
                    <div class="input-group">
                        <input type="text" class="form-control" datepicker-popup="yyyy-MM-dd" ng-model="data[row.field]" is-open="row.isOpend" name="{{row.field}}" />
                        <span class="input-group-btn">
                            <button type="button" class="btn btn-default" ng-click="openDate($event,row)" ><i class="glyphicon glyphicon-calendar"></i></button>
                        </span>
                    </div>
                    {{row.help}}
                </div>
            </div>
        </form>
    </div>
    <div class="modal-footer">
        <button class="btn btn-danger" ng-click="ok()">确认{{title}}</button>
        <button class="btn btn-warning" ng-click="cancel()">取消</button>
    </div>
    '''
]
.service '$form',['$modal',($modal)->
    ###
    提供4个参数，标题，模型，默认数据，验证函数
    模型在mongoose.Schema的基础上扩展了几个字段。

    验证函数支持两种形式：
    1. vali(data)
    返回String/null
    当返回String时代表验证未通过，表单继续显示
    当返回null时，验证通过，promise resolve

    2. vali(data,cb)
    异步验证方式
    回调函数cb支持一个err参数，当err为String时代表验证未通过，表单继续显示
    当err为null时，验证通过，promise resolve

    ###
    (title,schema,data,vali)->
        modalInstance = $modal.open
            templateUrl:'template/form.add.html'
            controller:'form.add.control'
            resolve:
                title:->
                    title
                schema:->
                    schema
                data:->
                    data
                vali:->
                    vali
        modalInstance.result
]
.controller 'form.add.control',($scope,$modalInstance,$filter,$msgbox,title,schema,data,vali)->
    $scope.title = title
    $scope.vali = vali

    $scope.rows = []
    $scope.data = {}

    defaultData = angular.extend {},data
    addWatch = (field,result,o)->
        $scope.$watch 'data',(value)->
            if value[field] is result
                o.if = true
            else
                o.if = false
        ,true
    # 每一行，最终初始数据，模型，初始数据
    formatSchema = (rows,data,schema,defaultData={})->
        for field,v of schema
            if not v.name or not v.type
                return formatSchema  rows,data,v,defaultData[field]
            o =
                name:v.name
                placeholder:v.placeholder
                field:field
                help:v.help
                style:v.style or 'input' # 默认为input样式
                enum:v.enum
                names:v.names or v.enum
                if:true
                isHide:v.isHide
            if v.ifField
                o.if = false
                addWatch v.ifField,v.ifResult,o

            if defaultData and defaultData[field]
                data[field] = defaultData[field]
            else
                data[field] = ''
                data[field] = v.default if v.default
            rows.push o
    formatSchema $scope.rows,$scope.data,schema,defaultData

    formatData = (schema,data)->
        result = {}
        for field,v of schema
            if not v.name or not v.type
                result[field] = formatData v,data
                continue
            if v.type is Number and v.style is 'date'
                result[field] = new Date($filter('date')(data[field],'yyyy-MM-dd')).getTime()
            else
                result[field] = data[field]
            if v.type is Boolean
                result[field] = if data[field] is 'true' then true else false
        result

    $scope.ok = ->
        data = formatData(schema,$scope.data)
        return $modalInstance.close data if not $scope.vali
        if $scope.vali.length is 1
            isSuccess = $scope.vali data
            return $msgbox isSuccess if isSuccess
            $modalInstance.close data
        if $scope.vali.length is 2
            $scope.vali data,(err)->
                return $msgbox err if err
                $modalInstance.close data

    $scope.cancel = ->
        $modalInstance.dismiss 'cancel'

    $scope.openDate = ($event,o)->
        $event.preventDefault()
        $event.stopPropagation()
        o.isOpend = true
