def call(String filePath) {
    def contents = readFile(filePath)

    def controller = contents.split('\n').findAll { line ->
        line.matches('^.*-controller;.*$')
    }

    def addresses = controller.collect { line ->
        line.split(';')[1]
    }

    def properAddress = addresses[0].split(',').find { address -> address.matches('^172.*$') || address.matches('^10.84.*$') }
    def controllerAddress = [controllerIP: properAddress]
    return controllerAddress
}
