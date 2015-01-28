
methods = [
	'create', 'createOnce', 'destroy', 'find', 'findOrCreate'
	'registerCollection', 'registerConnection', 'update'
]

module.exports = do ->

	adapter = {}

	adapter.syncable = false

	for method in methods

		do (method) -> adapter[method] = -> arguments[arguments.length - 1]()

	adapter
