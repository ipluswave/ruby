(function(window, angular, undefined) { 'use strict';
  angular.module('service_station').factory('ssWorkersManager', ['$http', '$q', 'ssWorker', function($http, $q, ssWorker) {
    var ssWorkersManager = {
      /* Private Methods */
      _pool: {},
      _retrieveInstance: function(id, workerData) {
        var instance = this._pool[id];

        if (instance) {
          instance.setData(workerData);
        } else {
          instance = new ssWorker(workerData);
          this._pool[id] = instance;
        }

        return instance;
      },
      _search: function(id) {
        return this._pool[id];
      },

      /* Public Methods */
      setWorker: function(workerData) {
        var scope = this;
        var worker = this._search(workerData.id);
        if (worker) {
          worker.setData(workerData);
        } else {
          worker = scope._retrieveInstance(workerData.id, workerData);
        }
        return worker;
      },
      loadAll: function() {
        var deferred = $q.defer();
        var scope = this;

        $http.get('/service_station/workers.json')
          .success(function(workersArray){
            var workers = [];
            workersArray.forEach(function(workerData) {
              var worker = scope._retrieveInstance(workerData.id, workerData);
              workers.push(worker);
            });
            deferred.resolve(workers);
          })
          .error(function() {
            deferred.reject();
          });
        return deferred.promise;
      },
      searchByIds: function(ids) {
        var scope = this;
        var workers = [];
        ids.forEach(function(id) {
          var worker = scope._search(id);
          if (worker) {
            workers.push(worker);
          }
        });
        return workers;
      },
      workerIdsAtDate: function(date) {
        if (!moment.isMoment(date)) { date = moment(date); }
        return $http.get('/service_station/workers/worked.json', { params: { date: date.format() } });
      },
      clear: function(){ this._pool = {} }
    };
    return ssWorkersManager;
  }]);
})(window, angular);
