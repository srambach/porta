// @flow

import React from 'react'

import { FormSelectOption } from '@patternfly/react-core'

type Props = {
  id: string,
  name: string,
  disabled?: boolean,
}

export function toFormSelectOption ({ id, name, disabled = false }: Props) {
  return <FormSelectOption isDisabled={disabled} key={id} value={id} label={name} />
}
