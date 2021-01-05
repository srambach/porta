import client from 'braintree-web/client'
import hostedFields from 'braintree-web/hosted-fields'
import threeDSecure from 'braintree-web/three-d-secure'

const form = document.querySelector('#customer_form')
const clientToken = form.dataset.clientToken
const braintreeNonce = document.querySelector('#braintree_nonce')

const hostedFieldOptions = {
  styles: {
    'input': {
      'font-size': '14px'
    },
    'input.invalid': {
      'color': 'red'
    },
    'input.valid': {
      'color': 'green'
    }
  },
  fields: {
    number: {
      selector: '#customer_credit_card_number',
      placeholder: '4111 1111 1111 1111'
    },
    cvv: {
      selector: '#customer_credit_card_cvv',
      placeholder: '123'
    },
    expirationDate: {
      selector: '#customer_credit_card_expiration_date',
      placeholder: 'MM/YY'
    }
  }
}

const create3DSecure = (clientInstance, payload) => {
  threeDSecure.create({
    version: 2,
    client: clientInstance
  }, function (threeDSecureErr, threeDSecure) {
    if (threeDSecureErr) {
      console.log('Error creating 3DSecure' + threeDSecureErr)
      return
    }
    braintreeNonce.value = payload['nonce']
    form.submit()
  })
}

client.create({
  authorization: clientToken
}, function (clientErr, clientInstance) {
  if (clientErr) {
    console.error(clientErr)
    return
  }

  hostedFields.create({
    client: clientInstance,
    ...hostedFieldOptions
  }, function (hostedFieldsErr, hostedFieldsInstance) {
    if (hostedFieldsErr) {
      console.error(hostedFieldsErr)
      return
    }

    form.addEventListener('submit', function (event) {
      event.preventDefault()
      hostedFieldsInstance.tokenize(function (tokenizeErr, payload) {
        if (tokenizeErr) {
          console.error(tokenizeErr)
          return
        }
        create3DSecure(clientInstance, payload)
      })
    })
  })
})
