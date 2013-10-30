package app

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestParseOptionsParsesTheInfrastructure(t *testing.T) {
	opts, err := parseOptions([]string{"bosh-agent", "-I", "foo"})
	assert.NoError(t, err)
	assert.Equal(t, opts.InfrastructureName, "foo")

	opts, err = parseOptions([]string{"bosh-agent"})
	assert.NoError(t, err)
	assert.Equal(t, opts.InfrastructureName, "")
}
