// @flow

import React from 'react'

import {
  SelectOption,
  SelectOptionObject as ISelectOptionObject
} from '@patternfly/react-core'

export interface Record {
  id: string,
  name: string
}

type Props = Record & {
  disabled?: boolean | void
}

export class SelectOptionObject implements ISelectOptionObject {
  id: string;
  name: string;

  constructor (item: Record) {
    this.id = String(item.id)
    this.name = item.name
  }

  toString (): string {
    return this.name
  }

  compareTo (other: Record): boolean {
    return this.id === other.id
  }
}

export const toSelectOption = ({ id, name, disabled = false }: Props) => (
  <SelectOption
    key={id}
    value={new SelectOptionObject({ id, name })}
    isDisabled={disabled}
  />
)
